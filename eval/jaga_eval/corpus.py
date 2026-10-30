"""Synthetic Manglish call corpus (#71): Muse Spark writes labelled call scripts, cached locally.

Run from eval/. Needs META_API_KEY in the environment; <out_dir> must be outside the repo (next to the clips):
  uv run python -m jaga_eval.corpus <out_dir> --limit 5        # small first run, check the token line
  uv run python -m jaga_eval.corpus <out_dir>                  # full run, about 300 scripts; cached
  uv run python -m jaga_eval.corpus <out_dir> --pick-reading   # 10 one-minute scripts, <out_dir>/reading/

Writes <out_dir>/spark.local.json (every reply), scripts.jsonl, manifest.csv. Nothing generated is committed.
The prompt never sees the 17 test clips; my.json terms are offered as optional vocabulary for scam kinds only.
"""

import argparse
import asyncio
import csv
import json
import os
import random
import re
import sys
from datetime import date
from pathlib import Path

from jaga import spark as spark_module
from jaga import stages

REPO = Path(__file__).resolve().parents[2]
STAGES = ["pretext", "authority", "fear", "isolation", "handoff", "money", "credentials"]
SCHEMA = {
    "type": "object",
    "additionalProperties": False,
    "required": ["lines"],
    "properties": {
        "lines": {
            "type": "array",
            "items": {
                "type": "object",
                "additionalProperties": False,
                "required": ["speaker", "text", "stage"],
                "properties": {
                    "speaker": {"enum": ["caller", "callee"]},
                    "text": {"type": "string"},
                    "stage": {"enum": [*STAGES, "none"]},
                },
            },
        }
    },
}
# kind -> (scam, hard negative, what happens)
KINDS = {
    "lhdn_tax": (
        True,
        False,
        "a fake LHDN officer says unpaid tax means a case will be filed unless the callee pays now",
    ),
    "pdrm_warrant": (
        True,
        False,
        "a fake PDRM or court officer says there is an arrest warrant over money laundering",
    ),
    "bnm_safe_account": (
        True,
        False,
        "a fake Bank Negara officer says the callee's account is frozen, move money to an 'akaun selamat'",
    ),
    "parcel_customs": (
        True,
        False,
        "a fake courier says an illegal parcel in the callee's name was caught, then hands over to 'police'",
    ),
    "bank_tac": (
        True,
        False,
        "a fake bank officer reports a suspicious transaction and asks for the TAC/OTP to 'cancel' it",
    ),
    "investment_group": (
        True,
        False,
        "a caller from a 'WhatsApp investment group' promises guaranteed returns and asks for a deposit",
    ),
    "family_emergency": (
        True,
        False,
        "a caller pretends to be the callee's child in an accident and begs for an urgent transfer",
    ),
    "bank_fraud_alert": (
        False,
        False,
        "a real bank checks a card transaction, never asks for the TAC, and says to call the card hotline",
    ),
    "courier_delivery": (False, False, "a real courier rider confirms a delivery address and time"),
    "family_chat": (False, False, "a relative chats about dinner, the kids and weekend plans"),
    "telco_plan": (False, False, "a real telco agent offers a plan upgrade and accepts a polite no"),
    "clinic_appointment": (False, False, "a clinic receptionist confirms or moves an appointment"),
    "lhdn_genuine": (
        False,
        True,
        "a real LHDN officer reminds about e-Filing and a refund, with no threat and nothing urgent",
    ),
    "police_followup": (
        False,
        True,
        "a real police officer follows up the callee's own police report and invites them to the station",
    ),
    "bank_tac_innocent": (
        False,
        True,
        "the callee phoned their own bank about a locked card; the agent warns never to share the TAC",
    ),
    "surprise_secret": (False, True, "a relative says 'jangan beritahu Mak' about a surprise birthday party"),
}
LANGS = {
    "malay": "mostly Bahasa Malaysia",
    "english": "mostly English",
    "manglish": "Manglish: Malaysian English mixed with Malay and particles like lah, kan, boleh",
}
LENGTHS = {"short": 60, "medium": 140, "long": 260}  # target words
VARIANTS = 3


def seeds(total: int = 300) -> list[dict]:
    grid = [
        {
            "id": f"{k}-{lang}-{n}-{v}",
            "kind": k,
            "scam": KINDS[k][0],
            "hard_negative": KINDS[k][1],
            "lang": lang,
            "length": n,
        }
        for k in KINDS
        for lang in LANGS
        for n in LENGTHS
        for v in range(VARIANTS)
    ]
    random.Random(0).shuffle(grid)  # a fixed shuffle, so --limit N is a mixed sample
    return grid[:total]


def prompt(seed: dict, pack: dict) -> tuple[str, str]:
    scam, _, story = KINDS[seed["kind"]]
    rules = (
        "You write synthetic phone-call scripts to test a scam-call detector in Malaysia. Reply JSON only: "
        '{"lines":[{"speaker":"caller"|"callee","text":...,"stage":...}]}. The caller starts. '
        f"stage is one of {STAGES} for a scam caller line showing that scam step, else 'none'. "
        + ("" if scam else "Every line of a genuine call has stage 'none'. ")
        + "Never use real names, phone numbers or account numbers."
    )
    vocab = ""
    if scam:
        terms = [*pack["keywords"], *pack["hardTriggers"]]
        vocab = f" Optional vocabulary the scammer may use: {', '.join(dict.fromkeys(terms))}."
    user = (
        f"Write a {'scam' if scam else 'genuine'} call: {story}. Language: {LANGS[seed['lang']]}. "
        f"About {LENGTHS[seed['length']]} words. Variation {seed['id'].rsplit('-', 1)[1]}.{vocab}"
    )
    return rules, user


def validate(raw: str) -> list[dict]:
    lines = json.loads(raw)["lines"]
    if not lines:
        raise ValueError("no lines")
    for ln in lines:
        if set(ln) != {"speaker", "text", "stage"} or ln["speaker"] not in ("caller", "callee"):
            raise ValueError("bad line")
        if not isinstance(ln["text"], str) or not ln["text"].strip() or ln["stage"] not in (*STAGES, "none"):
            raise ValueError("bad line")
    return lines


def save(path: Path, data) -> None:
    tmp = path.with_name(path.name + ".tmp")
    tmp.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
    os.replace(tmp, path)  # atomic: a crash never leaves a half-written cache


def check_out(out_dir) -> Path:
    out = Path(out_dir).resolve()
    if out == REPO or REPO in out.parents:
        raise ValueError(f"{out} is inside the repo: use a directory outside git")
    out.mkdir(parents=True, exist_ok=True)
    return out


async def generate(out_dir, spark, pack, limit=None) -> dict:
    """Asks Spark once per seed (twice if the reply fails validation), caching every reply. Returns counts."""
    out = check_out(out_dir)
    cache_path = out / "spark.local.json"
    cache = json.loads(cache_path.read_text(encoding="utf-8")) if cache_path.exists() else {}
    todo = seeds()[:limit]
    for seed in todo:
        if seed["id"] in cache:
            continue
        rules, user = prompt(seed, pack)
        usage = {"input_tokens": 0, "output_tokens": 0}
        for _ in range(2):
            raw, u = await spark.generate(rules, user, SCHEMA)
            for k in usage:
                usage[k] += u.get(k, 0)
            try:
                validate(raw)
                error = None
                break
            except (ValueError, KeyError, TypeError) as e:  # JSONDecodeError is a ValueError
                error = f"{type(e).__name__}: {e}"
        model = getattr(spark, "MODEL", "fake")
        cache[seed["id"]] = {
            "raw": raw,
            "error": error,
            "usage": usage,
            "model": model,
            "date": str(date.today()),
        }
        save(cache_path, cache)  # a failed seed stays cached too; delete its entry to retry
    rows, skipped = [], []
    for seed in todo:
        entry = cache[seed["id"]]
        if entry["error"]:
            skipped.append(seed["id"])
            continue
        lines = validate(entry["raw"])
        present = sorted({ln["stage"] for ln in lines} - {"none"}, key=lambda s: stages.RANK[s])
        n = sum(len(ln["text"].split()) for ln in lines)
        rows.append(
            {
                **seed,
                "lines": lines,
                "words": n,
                "stages": present,
                "model": entry["model"],
                "date": entry["date"],
            }
        )
    (out / "scripts.jsonl").write_text(
        "".join(json.dumps(r, ensure_ascii=False) + "\n" for r in rows), encoding="utf-8"
    )
    with open(out / "manifest.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["id", "kind", "label", "language_mix", "words", "stages", "model", "date"])
        for r in rows:
            label = "scam" if r["scam"] else "genuine"
            w.writerow(
                [
                    r["id"],
                    r["kind"],
                    label,
                    r["lang"],
                    r["words"],
                    "|".join(r["stages"]),
                    r["model"],
                    r["date"],
                ]
            )
    tin, tout = (sum(e["usage"][k] for e in cache.values()) for k in ("input_tokens", "output_tokens"))
    return {"scripts": len(rows), "skipped": skipped, "tokens_in": tin, "tokens_out": tout}


def pick(rows, scam: bool, n: int, hard_first: bool = False) -> list[dict]:
    """Greedy over one-minute scripts (120-160 words): most uncovered stages next; ties by id."""
    pool = [r for r in rows if r["scam"] == scam and 120 <= r["words"] <= 160]
    covered: set = set()
    chosen = []
    for i in range(n):
        want = [r for r in pool if r["hard_negative"]] if hard_first and i == 0 else pool
        if not want:
            raise ValueError(
                f"not enough 120-160 word {'scam' if scam else 'genuine'} scripts: run more seeds"
            )
        best = max(want, key=lambda r: (len(set(r["stages"]) - covered), r["id"]))
        chosen.append(best)
        pool.remove(best)
        covered |= set(best["stages"])
    return chosen


def count_terms(text: str, terms: list[str]) -> dict:
    """Occurrences per term, longest first; matched text is blanked so 'TAC' skips 'kod TAC'."""
    counts = {}
    for t in sorted(terms, key=len, reverse=True):
        pattern = re.compile(rf"(?<!\w){re.escape(t)}(?!\w)", re.IGNORECASE)
        counts[t] = len(pattern.findall(text))
        text = pattern.sub(lambda m: "\0" * len(m[0]), text)
    return counts


def write_new(path: Path, body: str = "", rows=None) -> None:
    """Never overwrites: an existing file is kept."""
    try:
        with open(path, "x", newline="", encoding="utf-8") as f:
            f.write(body)
            if rows:
                csv.writer(f).writerows(rows)
    except FileExistsError:
        print(f"kept existing {path.name}")


def pick_reading(out_dir, pack) -> list[str]:
    out = check_out(out_dir)
    rows = [json.loads(ln) for ln in (out / "scripts.jsonl").read_text(encoding="utf-8").splitlines()]
    chosen = [*pick(rows, True, 7), *pick(rows, False, 3, hard_first=True)]
    terms = list({t.lower(): t for t in [*pack["keywords"], *pack["hardTriggers"]]}.values())
    reading = out / "reading"
    reading.mkdir(exist_ok=True)
    table = [["clip", *terms]]
    for i, r in enumerate(chosen, 1):
        clip = f"rec_{i:02d}"
        text = " ".join(ln["text"] for ln in r["lines"])
        sheet = "\n".join(f"{ln['speaker'].upper()}: {ln['text']}" for ln in r["lines"])
        write_new(reading / f"{clip}.ref.txt", text + "\n")
        write_new(reading / f"{clip}.sheet.txt", sheet + "\n")
        counts = count_terms(text, terms)
        table.append([clip, *(counts[t] for t in terms)])
    write_new(reading / "keywords.csv", rows=table)
    return [r["id"] for r in chosen]


def main(argv=None, spark=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("out_dir")
    ap.add_argument("--limit", type=int)
    ap.add_argument("--pick-reading", action="store_true")
    args = ap.parse_args(argv)
    pack = stages.load_pack("my")
    if args.pick_reading:
        print("picked", *pick_reading(args.out_dir, pack))
        return 0
    spark = spark or spark_module.spark(pack)
    r = asyncio.run(generate(args.out_dir, spark, pack, args.limit))
    print(f"{r['scripts']} scripts, {len(r['skipped'])} skipped {r['skipped']}")
    print(
        f"tokens (all cached replies): {r['tokens_in']} in, {r['tokens_out']} out; price at Muse Spark's rate"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
