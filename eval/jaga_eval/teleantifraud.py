"""TeleAntiFraud-28k binary test (#18): text transcripts through the real app with fakes, fraud vs normal.

Usage: python -m jaga_eval.teleantifraud <path-to-test.json> [--out eval/reports]
Data is gated on Hugging Face (JimmyMa99/TeleAntiFraud, Apache-2.0); it stays under eval/data/teleantifraud/.
Never print or write transcript text.
"""

import argparse
import json
import os
import random
import re
import time
from dataclasses import dataclass
from pathlib import Path
from unittest import mock

from fastapi.testclient import TestClient
from starlette.websockets import WebSocketDisconnect

from jaga import asr, stages, telephony, twilio_auth
from jaga.fakes.twilio import media_stream
from jaga.main import app

CLASSES = ("fraud", "normal")
TOKEN = "eval-auth-token"
DEFAULT_OUT = Path(__file__).resolve().parents[1] / "reports"
TAG = re.compile(r"^([^\s:：]{1,20})[:：]\s*(.*)$")


@dataclass
class Call:
    label: str
    script: list[tuple[str, str]]


@dataclass
class Result:
    stage: str
    predicted: str


def parse_label(answer) -> str:
    if answer not in CLASSES:
        raise ValueError(f"unknown label {answer!r}")
    return answer


def transcript(prompt) -> str:
    content = [m for m in prompt if m.get("role") == "user"][-1]["content"]
    if isinstance(content, str):
        return content
    return "\n".join(p["text"] for p in content if p.get("type") == "text")


def to_script(text: str) -> list[tuple[str, str]]:
    lines = [ln.strip() for ln in text.splitlines() if ln.strip()]
    tags = [TAG.match(ln) for ln in lines]
    # shortcut: speaker tags are a guess (first speaker = caller); confirm against the real file.
    if lines and all(tags) and len({m[1] for m in tags}) == 2:
        first = tags[0][1]
        return [("caller" if m[1] == first else "user", m[2]) for m in tags if m[2]]
    return [("caller", ln) for ln in lines]


def load(path) -> list[Call]:
    records = json.loads(Path(path).read_text(encoding="utf-8"))
    if not records:
        raise ValueError("no calls")
    calls = []
    texts = {transcript(r["prompt"]) for r in records if any(m.get("role") == "user" for m in r["prompt"])}
    if len(records) > 1 and len(texts) == 1:
        raise ValueError("no transcripts: every record has the same text (audio only, needs ASR)")
    for i, r in enumerate(records):
        if not any(m.get("role") == "user" for m in r["prompt"]):
            raise ValueError(f"record {i} has no user message")
        calls.append(Call(parse_label(r["answer"]), to_script(transcript(r["prompt"]))))
    return calls


def replay(call: Call, index: int) -> Result:
    """Plays the call through the real app (fakes only) and reads the stage updates the app would get."""
    sid = f"CA_tafd_{index}"
    start, *media, stop = media_stream(sid, call.script)[1:]
    headers = {"X-Twilio-Signature": twilio_auth.signature("wss://testserver/twilio/media", {}, TOKEN)}
    env = {"JAGA_USE_FAKES": "true", "JAGA_DEFAULT_REGION": "my", "TWILIO_AUTH_TOKEN": TOKEN}
    updates = []
    with mock.patch.dict(os.environ, env), mock.patch.object(asr.MuseTranscriber, "FLUSH", 0.2):
        with TestClient(app) as client, client.websocket_connect("/twilio/media", headers=headers) as twilio:
            twilio.send_text(start)
            deadline = time.monotonic() + 5
            while sid not in telephony.calls:
                if time.monotonic() > deadline:
                    raise RuntimeError("the call never started")
                time.sleep(0.01)
            with client.websocket_connect(f"/calls/{sid}/stages") as stream:
                for msg in [*media, stop]:
                    twilio.send_text(msg)
                try:
                    while True:
                        updates.append(stream.receive_json())
                except WebSocketDisconnect:
                    pass
    stage = max((u["stage"] for u in updates), key=stages.RANK.get, default="none")
    fraud = stages.RANK[stage] >= stages.RANK["isolation"] or any(u["risk"] == "high" for u in updates)
    return Result(stage, "fraud" if fraud else "normal")


def metrics(truth, pred) -> dict:
    confusion = {
        t: {p: sum(1 for a, b in zip(truth, pred, strict=True) if (a, b) == (t, p)) for p in CLASSES}
        for t in CLASSES
    }
    out = {"n": len(truth), "confusion": confusion}
    for c in CLASSES:
        tp = confusion[c][c]
        predicted, actual = sum(confusion[t][c] for t in CLASSES), sum(confusion[c].values())
        p, r = tp / predicted if predicted else 0.0, tp / actual if actual else 0.0
        out[c] = {"precision": p, "recall": r, "f1": 2 * p * r / (p + r) if p + r else 0.0, "n": actual}
    out["macro_f1"] = sum(out[c]["f1"] for c in CLASSES) / 2
    out["weighted_f1"] = sum(out[c]["f1"] * out[c]["n"] for c in CLASSES) / len(truth)
    return out


def macro_f1_ci(truth, pred, resamples=1000, seed=0) -> tuple[float, float]:
    """95% percentile bootstrap over calls."""
    rng, pairs, scores = random.Random(seed), list(zip(truth, pred, strict=True)), []
    for _ in range(resamples):
        sample = [rng.choice(pairs) for _ in pairs]
        scores.append(metrics([a for a, _ in sample], [b for _, b in sample])["macro_f1"])
    scores.sort()
    return scores[int(0.025 * resamples)], scores[int(0.975 * resamples) - 1]


def summary(m: dict, ci: tuple[float, float], source: str) -> str:
    c = m["confusion"]
    mvp, stretch = ("met" if m["macro_f1"] >= x else "missed" for x in (0.75, 0.80))
    rows = "\n".join(
        f"| {k} | {m[k]['precision']:.3f} | {m[k]['recall']:.3f} | {m[k]['f1']:.3f} | {m[k]['n']} |"
        for k in CLASSES
    )
    return f"""# TeleAntiFraud-28k binary test (text path)

Data: TeleAntiFraud-28k binary test, file `{source}`
(Hugging Face JimmyMa99/TeleAntiFraud, Apache-2.0, gated access).
Jaga says fraud if the call reaches `isolation` or higher, or any update is a Warning. Fraud type ignored.
Fakes only (rules, no Muse Spark). The Malaysia pack has no Mandarin phrases yet (#36),
so a low score is expected.

n = {m["n"]}
MVP target 0.75: {mvp}; stretch 0.80: {stretch}
Caveat: speakers are mapped first tag = caller; if a call opens with the callee,
scam lines go to the user leg and are ignored.

| Metric | Value |
|---|---|
| Macro-F1 | {m["macro_f1"]:.3f} (95% bootstrap CI {ci[0]:.3f} to {ci[1]:.3f}) |
| Weighted F1 (paper reports this, arXiv:2503.24115 Table 4) | {m["weighted_f1"]:.3f} |

| Class | Precision | Recall | F1 | n |
|---|---|---|---|---|
{rows}

| True vs predicted | fraud | normal |
|---|---|---|
| fraud | {c["fraud"]["fraud"]} | {c["fraud"]["normal"]} |
| normal | {c["normal"]["fraud"]} | {c["normal"]["normal"]} |
"""


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("test_json")
    ap.add_argument("--out", default=str(DEFAULT_OUT))
    args = ap.parse_args(argv)
    calls = load(args.test_json)
    results = [replay(c, i) for i, c in enumerate(calls)]
    truth, pred = [c.label for c in calls], [r.predicted for r in results]
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    rows = [
        {"id": i, "true": t, "predicted": p, "stage": r.stage}
        for i, (t, p, r) in enumerate(zip(truth, pred, results, strict=True))
    ]
    (out / "teleantifraud.local.json").write_text(json.dumps({"calls": rows}, indent=1), encoding="utf-8")
    text = summary(metrics(truth, pred), macro_f1_ci(truth, pred), Path(args.test_json).name)
    (out / "teleantifraud.md").write_text(text, encoding="utf-8")
    print(text)


if __name__ == "__main__":
    main()
