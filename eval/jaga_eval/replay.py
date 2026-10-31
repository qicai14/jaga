"""Replay harness (#24): recorded calls through seam 1 exactly as live calls go, with real or fake clients.

Usage: python -m jaga_eval.replay <calls.json> [--transcriber muse|fake] [--spark meta|fake|open|off]
                                  [--speed X] [--limit N] [--out eval/reports]
`calls.json` is a list of {"id", "split"?, "region"?, "audio"?: {"caller": p, "user"?: p},
"script"?: [[leg, line]]}.
Audio paths are relative to the file; it is decoded to 8 kHz mu-law and streamed in 20 ms Twilio chunks at
`speed` x real time (default 1.0 with Muse, 0 = unpaced with the fake). The fake transcriber hears `script`
lines instead of audio (cheap runs); Muse needs `audio`. Muse and Spark need META_API_KEY.
Per call it records every `stage-update`, every family alert and the timings. The full report holds masked
transcript quotes, so it stays in `eval/reports/replay.local.json` (untracked); only numbers are printed.
Never print or write transcript text. Held-out rows (`split` heldout) are refused: they only go through
`jaga_eval.report --final`. A row's `split` stays empty unless the file sets it; the report refuses that.
"""

import argparse
import base64
import contextlib
import json
import os
import subprocess
import threading
import time
from dataclasses import dataclass, field
from pathlib import Path
from unittest import mock

from fastapi.testclient import TestClient
from starlette.websockets import WebSocketDisconnect

from jaga import alerts, asr, spark, stages, telephony, twilio_auth
from jaga.fakes.push import FakePush
from jaga.fakes.spark import FakeSpark
from jaga.fakes.transcribe import FakeTranscriber
from jaga.fakes.twilio import media_stream
from jaga.main import app
from jaga_eval.asr_rescore import score
from jaga_eval.open_spark import CountingSpark, open_spark

DEFAULT_OUT = Path(__file__).resolve().parents[1] / "reports"
TOKEN = "eval-auth-token"
TRACKS = {"caller": "inbound", "user": "outbound"}
CHUNK = 160  # bytes of 8 kHz mu-law in 20 ms
CHUNK_SECONDS = 0.02


@dataclass
class Call:
    id: str
    region: str = "my"
    audio: dict[str, Path] = field(default_factory=dict)  # leg -> recording
    script: list[tuple[str, str]] = field(default_factory=list)
    # Ground truth for the metrics report (#25): label scam|genuine, split dev|heldout, reference = human
    # transcript file (outside git), seconds = length of a script call, triggerAt = trigger second,
    # moneyAt = audio second where the caller's first money or credentials line starts (a human label).
    label: str = ""
    split: str = ""  # dev|heldout; the report refuses anything else
    reference: Path | None = None
    seconds: float | None = None
    triggerAt: float | None = None
    moneyAt: float | None = None


class RecordingPush(FakePush):
    """The family-alert client for replays: records each alert with the time it was asked for."""

    def __init__(self, clock):
        super().__init__()
        self.clock, self.at = clock, []

    async def send(self, token: str, alert: dict) -> None:
        self.at.append(self.clock())
        await super().send(token, alert)


def load(path) -> list[Call]:
    path = Path(path)
    records = json.loads(path.read_text(encoding="utf-8"))
    if not records:
        raise ValueError("no calls")
    calls = []
    for r in records:
        audio = {leg: path.parent / p for leg, p in r.get("audio", {}).items()}
        if bad := set(audio) - set(TRACKS):
            raise ValueError(f"call {r['id']}: unknown leg {sorted(bad)}")
        script = [(leg, line) for leg, line in r.get("script", [])]
        if not audio and not script:
            raise ValueError(f"call {r['id']} has neither audio nor script")
        ref = r.get("reference")
        calls.append(
            Call(
                r["id"],
                r.get("region", "my"),
                audio,
                script,
                r.get("label", ""),
                r.get("split", ""),
                path.parent / ref if ref else None,
                r.get("seconds"),
                r.get("triggerAt"),
                r.get("moneyAt"),
            )
        )
    return calls


def mulaw(path) -> bytes:
    """A recording as 8 kHz mono G.711 mu-law, the format Twilio streams."""
    done = subprocess.run(
        ["ffmpeg", "-v", "error", "-i", str(path), "-ar", "8000", "-ac", "1", "-f", "mulaw", "-"],
        check=True,
        capture_output=True,
    )
    return done.stdout


def audio_plan(sid: str, audio: dict[str, bytes], region: str) -> tuple[str, list[tuple[float, str]], str]:
    """(start, [(seconds into the call, media message)], stop); both legs' chunks are interleaved by time."""
    start = json.dumps(
        {
            "event": "start",
            "start": {
                "callSid": sid,
                "tracks": ["inbound", "outbound"],
                "customParameters": {"region": region},
            },
        }
    )
    timed = []
    for leg, data in audio.items():
        for i in range(0, len(data), CHUNK):
            payload = base64.b64encode(data[i : i + CHUNK]).decode()
            msg = {"event": "media", "media": {"track": TRACKS[leg], "payload": payload}}
            timed.append((i // CHUNK * CHUNK_SECONDS, json.dumps(msg)))
    timed.sort(key=lambda t: t[0])  # stable: legs keep their order within one instant
    return start, timed, json.dumps({"event": "stop"})


def script_plan(sid: str, script, region: str) -> tuple[str, list[tuple[float, str]], str]:
    start, *media, stop = media_stream(sid, script, region)[1:]
    return start, [(i * CHUNK_SECONDS, m) for i, m in enumerate(media)], stop


def replay(call: Call, index: int, transcriber: str, spark_client: str, speed: float) -> dict:
    """Plays one call through the real app and returns its report (updates, family alerts, timings)."""
    sid = f"CA_replay_{index}"
    telephony.calls.pop(sid, None)  # the sid repeats across arms: never meet an earlier arm's ended Call
    alerts.sent.pop(sid, None)
    if transcriber == "muse":
        if not call.audio:
            raise ValueError(f"call {call.id}: the Muse transcriber needs audio")
        start, media, stop = audio_plan(sid, {leg: mulaw(p) for leg, p in call.audio.items()}, call.region)
    else:
        if not call.script:
            raise ValueError(f"call {call.id}: the fake transcriber needs a script")
        start, media, stop = script_plan(sid, call.script, call.region)

    t0 = time.monotonic()
    clock = lambda: round(time.monotonic() - t0, 3)  # noqa: E731
    push = RecordingPush(clock)
    headers = {"X-Twilio-Signature": twilio_auth.signature("wss://testserver/twilio/media", {}, TOKEN)}
    env = {"TWILIO_AUTH_TOKEN": TOKEN, "JAGA_FAMILY_TOKENS": "eval-co-pilot"}
    env["JAGA_USE_FAKES"] = "false"  # the clients below are chosen here, one by one
    patches = [mock.patch.object(spark, "_http", None)]  # a client is bound to one event loop: one per replay
    if transcriber == "fake":
        patches.append(mock.patch.object(asr, "transcriber", lambda pack: FakeTranscriber()))
    counts = {
        "failed": 0,
        "timedOut": 0,
    }  # what the pipeline swallows, counted by a wrapper
    make = {"fake": FakeSpark, "off": FakeSpark, "open": open_spark, "meta": spark.spark}[spark_client]
    patches.append(mock.patch.object(spark, "spark", lambda pack: CountingSpark(make(pack), counts, pack)))
    if spark_client == "off":  # rules only: the cap is 0, so telephony never asks Spark
        patches.append(mock.patch.object(spark, "MAX_CALLS", 0))
    updates, failure = [], []
    heard: dict[str, list[int]] = {}  # leg -> [lines, characters]: how much was transcribed, never what
    text: list[str] = []  # in memory only, to score against the reference; never written
    real_hear = telephony.hear

    async def counting_hear(call, leg, line):
        seen = heard.setdefault(leg, [0, 0])
        seen[0] += 1
        seen[1] += len(line)
        text.append(line)
        await real_hear(call, leg, line)

    patches.append(mock.patch.object(telephony, "hear", counting_hear))

    def follow(stream):
        try:
            while True:
                msg = stream.receive_json()  # stamp after the wait: when it arrived
                updates.append((clock(), msg))
        except WebSocketDisconnect:
            pass
        except Exception as e:  # noqa: BLE001 - type only, the message could quote a transcript
            failure.append(type(e).__name__)

    with contextlib.ExitStack() as stack:
        for patch in [mock.patch.dict(os.environ, env), *patches]:
            stack.enter_context(patch)
        with TestClient(app) as client, client.websocket_connect("/twilio/media", headers=headers) as twilio:
            twilio.send_text(start)
            deadline = time.monotonic() + 5
            while sid not in telephony.calls:
                if time.monotonic() > deadline:
                    raise RuntimeError("the call never started")
                time.sleep(0.01)
            telephony.calls[sid].push = push  # the Call bound alerts.push at import; nothing is sent yet
            with client.websocket_connect(f"/calls/{sid}/stages") as stream:
                reader = threading.Thread(target=follow, args=(stream,))
                reader.start()
                t0 = time.monotonic()  # audio second 0 is the first chunk sent
                for offset, msg in media:
                    if speed > 0 and (wait := t0 + offset / speed - time.monotonic()) > 0:
                        time.sleep(wait)
                    twilio.send_text(msg)
                streamed = clock()
                twilio.send_text(stop)
                reader.join()
    if failure:
        raise RuntimeError(f"call {call.id}: the stage stream failed ({failure[0]})")
    live = telephony.calls[sid]
    rep = report(
        call, updates, push, streamed, clock(), call.seconds or (media[-1][0] if media else 0.0), heard
    )
    rep["speed"] = speed
    rep["spark"] = {"asked": live.sparked, **counts}
    if call.reference:
        s = score(call.reference.read_text(encoding="utf-8"), " ".join(text))
        rep["asr"] = {"words": s.words, "chars": s.chars}  # edit counts only
    return rep


def report(call, updates, push, streamed, wall, audio_seconds, heard) -> dict:
    first, warning = {}, None
    for at, u in updates:
        first.setdefault(u["stage"], at)
        if warning is None and u["risk"] == "high":
            warning = at
    final = max((u["stage"] for _, u in updates), key=stages.RANK.get, default="none")
    return {
        "id": call.id,
        "audioSeconds": round(audio_seconds, 3),
        "streamedAt": streamed,
        "endedAt": wall,
        "heard": {leg: {"lines": n, "characters": c} for leg, (n, c) in heard.items()},
        "finalStage": final,
        "firstWarningAt": warning,
        "stageFirstAt": first,
        "updates": [{"at": at, **u} for at, u in updates],
        "familyAlerts": [{"at": at, **a} for at, (_, a) in zip(push.at, push.sent, strict=True)],
    }


def summary(reports: list[dict], transcriber: str, spark_client: str, speed: float) -> dict:
    """Numbers only: safe to print."""
    finals: dict[str, int] = {}
    for r in reports:
        finals[r["finalStage"]] = finals.get(r["finalStage"], 0) + 1
    warned = [r["firstWarningAt"] for r in reports if r["firstWarningAt"] is not None]
    return {
        "calls": len(reports),
        "transcriber": transcriber,
        "spark": spark_client,
        "speed": speed,
        "finalStages": finals,
        "calls with no transcript": sum(1 for r in reports if not r["heard"]),
        "calls with a warning": len(warned),
        "calls with a family alert": sum(1 for r in reports if r["familyAlerts"]),
        "stage updates": sum(len(r["updates"]) for r in reports),
        "median first warning (s)": sorted(warned)[len(warned) // 2] if warned else None,
    }


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("calls_json")
    ap.add_argument("--transcriber", choices=["muse", "fake"], default="fake")
    ap.add_argument("--spark", choices=["meta", "fake", "open", "off"], default="fake")
    ap.add_argument("--speed", type=float, help="x real time; 0 = unpaced (default: 1 with Muse, else 0)")
    ap.add_argument("--limit", type=int, help="only the first N calls")
    ap.add_argument("--out", default=str(DEFAULT_OUT))
    args = ap.parse_args(argv)
    calls = load(args.calls_json)[: args.limit]
    if any(c.split == "heldout" for c in calls):
        raise SystemExit(
            "held-out rows: run them once through `python -m jaga_eval.report --split heldout --final`"
        )
    if (args.transcriber == "muse" or args.spark == "meta") and not os.environ.get("META_API_KEY"):
        raise SystemExit("META_API_KEY is not set")
    speed = args.speed if args.speed is not None else (1.0 if args.transcriber == "muse" else 0.0)
    reports = []
    for i, call in enumerate(calls):
        reports.append(replay(call, i, args.transcriber, args.spark, speed))
        print(f"{call.id}: {reports[-1]['finalStage']} in {reports[-1]['endedAt']} s")
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    result = {"summary": summary(reports, args.transcriber, args.spark, speed), "calls": reports}
    (out / "replay.local.json").write_text(json.dumps(result, indent=1, ensure_ascii=False), encoding="utf-8")
    print(json.dumps(result["summary"], indent=1))


if __name__ == "__main__":
    main()
