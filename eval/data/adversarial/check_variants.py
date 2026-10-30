"""Structure checks for variants.csv, sequences.csv and labels_first_pass.csv.

Usage: python3 -I check_variants.py [dir]   (default: this file's folder)
Exits 1 on any problem. Does not run the detector.
"""
import csv
import sys
from collections import Counter
from pathlib import Path

STAGES = {"none", "pretext", "authority", "fear", "isolation", "handoff", "money", "credentials"}
SPARK_STAGES = STAGES - {"none", "pretext"}
TYPES = {
    "paraphrase", "manglish", "injection", "evasion", "near_miss", "ambiguous", "coverage", "output_attack",
}
TARGETS = {"rules", "spark", "both"}
YESNO = {"yes", "no"}


def rows(path):
    with open(path, encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def main(base):
    errs = []
    err = errs.append
    labels = {r["line_id"]: r for r in rows(base / "labels_first_pass.csv")}
    variants = rows(base / "variants.csv")
    seq = rows(base / "sequences.csv")

    ids = [r["variant_id"] for r in variants]
    if len(ids) != len(set(ids)):
        err("duplicate variant_id")
    if len({r["text"] for r in variants}) != len(variants):
        err("duplicate variant text")
    for r in variants:
        v = r["variant_id"]
        if r["label"] not in STAGES:
            err(f"{v}: bad label {r['label']!r}")
        if r["variant_type"] not in TYPES:
            err(f"{v}: bad variant_type")
        if r["target"] not in TARGETS:
            err(f"{v}: bad target")
        if r["expect_hard_trigger"] not in YESNO:
            err(f"{v}: expect_hard_trigger must be yes/no")
        if r["usage"] != "test_only":
            err(f"{v}: usage must be test_only")
        if not r["text"].strip():
            err(f"{v}: empty text")
        if r["source"] == "corpus":
            p = r["parent_line_id"]
            if p not in labels:
                err(f"{v}: unknown parent {p}")
            else:
                if labels[p]["split"] != r["parent_split"]:
                    err(f"{v}: parent_split mismatch")
                if labels[p]["draft_label"] != r["label"]:
                    err(f"{v}: label differs from parent {p}")
        elif r["parent_line_id"] or r["parent_split"]:
            err(f"{v}: synthetic row has a parent")
        if r["expect_spark_call"] in YESNO:
            want = "yes" if r["label"] in SPARK_STAGES else "no"
            if r["expect_spark_call"] != want:
                err(f"{v}: expect_spark_call {r['expect_spark_call']} but label {r['label']}")
        if r["expect_spark_call"] == "yes" and not r["expected_phrase_prefix"].startswith("my."):
            if r["expected_phrase_prefix"] != "n/a":
                err(f"{v}: bad expected_phrase_prefix")

    calls = {}
    for r in seq:
        calls.setdefault(r["call_id"], []).append(r)
    for cid, ls in calls.items():
        nums = [int(r["line_no"]) for r in ls]
        if nums != list(range(1, len(ls) + 1)):
            err(f"{cid}: line_no not 1..n in order")
        for r in ls:
            if r["label"] not in STAGES:
                err(f"{cid}/{r['line_no']}: bad label")
            if r["leg"] not in {"caller", "user"}:
                err(f"{cid}/{r['line_no']}: bad leg")
            if r["usage"] != "test_only":
                err(f"{cid}/{r['line_no']}: usage must be test_only")
        c = ls[0]["caught_before_line"]
        if c:
            first = next(
                (
                    int(r["line_no"])
                    for r in ls
                    if r["leg"] == "caller" and r["label"] in {"money", "credentials"}
                ),
                None,
            )
            if first is None or int(c) != first:
                err(f"{cid}: caught_before_line {c} is not the first caller money/credentials line ({first})")

    print(f"variants: {len(variants)} {dict(Counter(r['variant_type'] for r in variants))}")
    print(f"sequences: {len(calls)} calls, {len(seq)} lines")
    for e in errs:
        print("ERROR", e)
    print("OK" if not errs else f"{len(errs)} problem(s)")
    return 1 if errs else 0


if __name__ == "__main__":
    sys.exit(main(Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parent))
