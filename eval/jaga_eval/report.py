"""Metrics report and ablation (#25): the plan.md targets, each with n and a bootstrap 95% CI.

Usage: python -m jaga_eval.report <calls.json> [--transcriber muse|fake] [--speed X] [--arms ...]
                                  [--spark-usd P] [--asr-usd-per-min P] [--split dev|heldout --final]
Spark-only calls Spark on every caller line with a fixed placeholder stage (pretext, risk low); its latency is
one Spark call, not comparable with the pipeline arms. ASR is scored once (first arm, with Muse only).
Arms: rules (Spark off), rules+spark, rules+open (Muse Spark Open on Baseten), spark-only (the Spark client
judges every caller line of a `script`, no rules). Each call in calls.json needs `label` (scam|genuine) and
`split`; `triggerAt`, `reference`, `seconds` are optional (see replay.Call). Prices are inputs, never guessed.

The held-out split is for one final run: it needs --final, and the report is numbers only. Never read its
failures to change rules, prompts or thresholds (eval/AGENTS.md). Misses are reported as misses.
"""

import argparse
import asyncio
import os
import random
import time
from pathlib import Path

import httpx

from jaga import spark as spark_module
from jaga import stages
from jaga_eval import replay
from jaga_eval.asr_rescore import Score, boot_pooled, pooled

ARMS = ["rules", "rules+spark", "rules+open", "spark-only"]
SPARK_FOR_ARM = {"rules": "off", "rules+spark": "meta", "rules+open": "open"}
LATE_BEFORE_TRIGGER = 0.0  # a Warning before the labelled trigger line is clamped to 0 s and counted
MVP = {"caught": 0.90, "false_per_10h": 1.0, "p95_s": 2.0}
STRETCH = {"caught": 0.95, "false_per_10h": 0.0, "p95_s": 1.5}


def ci(items, stat, resamples=1000, seed=0):
    """95% percentile bootstrap over calls; None when there is nothing to resample."""
    if not items:
        return None
    rng = random.Random(seed)
    xs = sorted(v for _ in range(resamples) if (v := stat([rng.choice(items) for _ in items])) is not None)
    return (xs[int(0.025 * len(xs))], xs[int(0.975 * len(xs)) - 1]) if xs else None


def quantile(xs, q):
    xs = sorted(xs)
    return xs[min(len(xs) - 1, int(q * len(xs)))] if xs else None


def caught(rep) -> bool:
    """GLOSSARY: a Warning before the first money or credentials stage (one raised by that line is late)."""
    ups = rep["updates"]
    high = next((i for i, u in enumerate(ups) if u["risk"] == "high"), None)
    money = next((i for i, u in enumerate(ups) if stages.RANK[u["stage"]] >= stages.RANK["money"]), None)
    return high is not None and (money is None or high < money)


def rate(flags):
    return sum(flags) / len(flags) if flags else None


def rule_of_three(genuine):
    """No false alarm seen: the 95% upper bound is 3 events over the hours observed (per 10 h)."""
    hours = sum(r["audioSeconds"] for r in genuine) / 3600
    return (0.0, 30 / hours) if hours else None


def false_per_10h(reps):
    hours = sum(r["audioSeconds"] for r in reps) / 3600
    return 10 * sum(r["firstWarningAt"] is not None for r in reps) / hours if hours else None


def metrics(reps: list[dict], labels: dict[str, str], spark_usd=None, asr_usd_per_min=None) -> dict:
    scam = [r for r in reps if labels[r["id"]] == "scam"]
    genuine = [r for r in reps if labels[r["id"]] == "genuine"]
    raw = [r["ttw"] for r in scam if r.get("ttw") is not None and caught(r)]
    ttw = [max(0.0, t) for t in raw]  # a Warning before the trigger line is 0 s, never a negative latency
    asr = [Score(tuple(r["asr"]["words"]), tuple(r["asr"]["chars"])) for r in reps if "asr" in r]
    asked = sum(r["spark"]["asked"] for r in reps)
    minutes = sum(r["audioSeconds"] for r in reps) / 60
    priced = spark_usd is not None and asr_usd_per_min is not None and reps
    costs = [
        r["spark"]["asked"] * (spark_usd or 0) + r["audioSeconds"] / 60 * (asr_usd_per_min or 0) for r in reps
    ]
    false_alarms = sum(r["firstWarningAt"] is not None for r in genuine)
    return {
        "scam_n": len(scam),
        "genuine_n": len(genuine),
        "caught": rate([caught(r) for r in scam]),
        "caught_ci": ci(scam, lambda s: rate([caught(r) for r in s])),
        "missed": len([r for r in scam if not caught(r)]),
        "genuine_hours": sum(r["audioSeconds"] for r in genuine) / 3600,
        "false_alarms": false_alarms,
        "false_per_10h": false_per_10h(genuine),
        "false_ci": ci(genuine, false_per_10h) if false_alarms else rule_of_three(genuine),
        "genuine_cautions": sum(
            r["firstWarningAt"] is None and any(u["risk"] == "medium" for u in r["updates"]) for r in genuine
        ),
        "ttw_n": len(ttw),
        "ttw_early": sum(t < 0 for t in raw),
        "p50": quantile(ttw, 0.5),
        "p50_ci": ci(ttw, lambda s: quantile(s, 0.5)),
        "p95": quantile(ttw, 0.95),
        "p95_ci": ci(ttw, lambda s: quantile(s, 0.95)),
        "cost_per_call": sum(costs) / len(reps) if priced else None,
        "cost_ci": ci(costs, lambda s: sum(s) / len(s)) if priced else None,
        "spark_asked": asked,
        "spark_failed": sum(r["spark"]["failed"] for r in reps),
        "spark_timed_out": sum(r["spark"]["timedOut"] for r in reps),
        "audio_minutes": minutes,
        "asr_n": len(asr),
        "wer": pooled(asr, "words") if asr else None,
        "wer_ci": boot_pooled(asr, "words") if asr else None,
        "cer": pooled(asr, "chars") if asr else None,
        "cer_ci": boot_pooled(asr, "chars") if asr else None,
    }


async def _spark_only(call, client) -> dict:
    """Spark alone judges each caller line (masked, last 5 lines); no stage rules. Script calls only."""
    mask = stages.StageTracker(stages.load_pack(call.region)).mask
    said, updates, first_warning, ttw = [], [], None, None
    asked = failed = timed_out = 0
    for leg, line in call.script:
        if leg != "caller":
            continue
        said.append(mask(line))
        asked += 1
        t = time.monotonic()
        try:
            async with asyncio.timeout(spark_module.TIMEOUT):
                v = spark_module.Verdict.model_validate(
                    await client.assess("pretext", "low", " ".join(said[-5:]))
                )
        except Exception as e:  # noqa: BLE001 - counted by type, never quoted
            failed += 1
            timed_out += isinstance(e, TimeoutError | httpx.TimeoutException)
            continue
        latency = time.monotonic() - t
        if not updates or (updates[-1]["stage"], updates[-1]["risk"]) != (v.stage, v.risk):
            updates.append({"stage": v.stage, "risk": v.risk})
        if v.risk == "high" and first_warning is None:
            first_warning, ttw = time.monotonic(), latency
    return {
        "id": call.id,
        "audioSeconds": call.seconds or 0.0,
        "firstWarningAt": first_warning,
        "updates": updates,
        "ttw": ttw,
        "spark": {"asked": asked, "failed": failed, "timedOut": timed_out},
    }


def run_arm(calls, arm, transcriber, speed) -> list[dict]:
    if arm == "spark-only":
        if any(not c.script for c in calls):
            raise ValueError("spark-only needs script calls (no audio transcription in this arm)")
        os.environ.setdefault("JAGA_USE_FAKES", "false")
        client = spark_module.spark(stages.load_pack("my"))
        return [asyncio.run(_spark_only(c, client)) for c in calls]
    reps = [replay.replay(c, i, transcriber, SPARK_FOR_ARM[arm], speed) for i, c in enumerate(calls)]
    for c, r in zip(calls, reps, strict=True):
        wall = r["firstWarningAt"]
        r["ttw"] = (
            wall - c.triggerAt / speed if wall is not None and c.triggerAt is not None and speed > 0 else None
        )
    return reps


def _f(x, pct=False):
    return "n/a" if x is None else (f"{x:.1%}" if pct else f"{x:.3g}")


def _c(v, pct=False):
    return "n/a" if v is None else f"[{_f(v[0], pct)}, {_f(v[1], pct)}]"


def verdict(value, target, stretch, higher_better, span) -> str:
    if value is None:
        return "not measured"
    ok = value >= target if higher_better else value <= target
    met_stretch = value >= stretch if higher_better else value <= stretch
    note = " (CI spans the target)" if span and span[0] <= target <= span[1] else ""
    return ("met MVP and stretch" if met_stretch else "met MVP, missed stretch" if ok else "missed") + note


def markdown(results: dict[str, dict], split: str, source: str) -> str:
    out = [
        f"# Metrics report ({split} split)",
        "",
        f"Calls file `{source}`. 95% percentile bootstrap CIs over calls. Numbers only.",
        "Cautions on genuine calls are listed separately and are not false alarms (GLOSSARY.md).",
        "Spark failures and timeouts count as the rules-only answer. Latency is wall seconds from the",
        "labelled trigger line to the Warning (spark-only: that Spark call). Targets: docs/plan.md.",
        "Misses are reported as misses; this split is never tuned on.",
        "Time to Warning covers caught scams that have a `triggerAt` only; a Warning before the trigger",
        "line is clamped to 0 s and counted. With zero false alarms the CI upper bound is 3 / hours.",
        "Spark-only asks about every caller line with a fixed placeholder (stage pretext, risk low), so its",
        "latency is one Spark call, not comparable with the pipeline arms. Transcription is scored once,",
        "in the first arm (every arm hears the same audio); rows are absent without `--transcriber muse`.",
        "",
    ]
    for arm, m in results.items():
        n = m["scam_n"] + m["genuine_n"]
        fa = f"False alarms per 10 h genuine ({m['false_alarms']} in {m['genuine_hours']:.3g} h)"
        rows = [
            ("Scams caught before `money`", m["scam_n"], m["caught"], m["caught_ci"], True, "caught"),
            (fa, m["genuine_n"], m["false_per_10h"], m["false_ci"], False, "false_per_10h"),
            ("Time to Warning p50 (s)", m["ttw_n"], m["p50"], m["p50_ci"], False, None),
            ("Time to Warning p95 (s)", m["ttw_n"], m["p95"], m["p95_ci"], False, "p95_s"),
            ("Cost per call (USD, given prices)", n, m["cost_per_call"], m["cost_ci"], False, None),
            ("Transcription WER", m["asr_n"], m["wer"], m["wer_ci"], False, None),
            ("Transcription CER", m["asr_n"], m["cer"], m["cer_ci"], False, None),
        ]
        out += [f"## {arm}", "", "| Metric | n | Value | 95% CI | MVP / stretch |", "|---|---|---|---|---|"]
        for name, count, value, span, higher, key in rows:
            if count == 0 and ("WER" in name or "CER" in name):
                continue
            pct = key == "caught" or "WER" in name or "CER" in name
            v = verdict(value, MVP[key], STRETCH[key], higher, span) if key else ""
            out.append(f"| {name} | {count} | {_f(value, pct)} | {_c(span, pct)} | {v} |")
        out += [
            f"| Genuine calls with only a Caution | {m['genuine_n']} | {m['genuine_cautions']} | | |",
            "",
            f"Caught scams with a Warning before the trigger line: {m['ttw_early']}.",
            f"Scams missed: {m['missed']} of {m['scam_n']}. Spark asked {m['spark_asked']} times, "
            f"failed {m['spark_failed']}, timed out {m['spark_timed_out']}.",
            "",
        ]
    return "\n".join(out)


def check_arms(calls, arms, transcriber):
    """Fail before any paid arm runs: calls fit every arm, and the keys are there."""
    env = os.environ
    fakes = env.get("JAGA_USE_FAKES", "").lower() == "true"
    for arm in arms:
        if arm == "spark-only" and any(not c.script for c in calls):
            raise SystemExit("spark-only needs a script on every call")
        for c in calls if arm != "spark-only" else []:
            if not (c.audio if transcriber == "muse" else c.script):
                raise SystemExit(
                    f"call {c.id}: the {transcriber} transcriber needs {'audio' if c.audio else 'a script'}"
                )
        need = {"rules+open": ["BASETEN_API_KEY", "BASETEN_BASE_URL"]}.get(arm, [])
        if arm == "rules+spark" or transcriber == "muse" or (arm == "spark-only" and not fakes):
            need = [*need, "META_API_KEY"]
        if missing := [k for k in need if not env.get(k)]:
            raise SystemExit(f"arm {arm}: {', '.join(missing)} not set")


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("calls_json")
    ap.add_argument("--arms", nargs="+", choices=ARMS, default=ARMS)
    ap.add_argument("--transcriber", choices=["muse", "fake"], default="fake")
    ap.add_argument("--speed", type=float, help="x real time; 0 = unpaced (default: 1 with Muse, else 0)")
    ap.add_argument("--split", choices=["dev", "heldout"], default="dev")
    ap.add_argument("--final", action="store_true", help="required for the held-out split: one final run")
    ap.add_argument("--spark-usd", type=float, help="price of one Spark call")
    ap.add_argument("--asr-usd-per-min", type=float, help="price of one audio minute transcribed")
    ap.add_argument("--out", default=str(replay.DEFAULT_OUT))
    args = ap.parse_args(argv)
    if args.split == "heldout" and not args.final:
        raise SystemExit("the held-out split is for one final run: pass --final, and never tune on it")
    speed = args.speed if args.speed is not None else (1.0 if args.transcriber == "muse" else 0.0)
    calls = [c for c in replay.load(args.calls_json) if c.split == args.split]
    if bad := [c.id for c in calls if c.label not in ("scam", "genuine")]:
        raise SystemExit(f"calls without label scam|genuine: {bad}")
    if not calls:
        raise SystemExit(f"no calls in the {args.split} split")
    labels = {c.id: c.label for c in calls}
    check_arms(calls, args.arms, args.transcriber)
    out = Path(args.out)
    target = out / f"metrics-{args.split}.md"
    if args.split == "heldout" and target.exists():
        raise SystemExit(f"{target} exists: the held-out split is run once; never overwrite it")
    results = {}
    for n, arm in enumerate(args.arms):
        reps = run_arm(calls, arm, args.transcriber, speed)
        if (
            args.transcriber != "muse" or n
        ):  # scored once: the first arm; fake transcripts are the script itself
            for r in reps:
                r.pop("asr", None)
        results[arm] = metrics(reps, labels, args.spark_usd, args.asr_usd_per_min)
    out.mkdir(parents=True, exist_ok=True)
    text = markdown(results, args.split, Path(args.calls_json).name)
    target.write_text(text, encoding="utf-8")
    print(text)


if __name__ == "__main__":
    main()
