import asyncio
import csv
import json
from pathlib import Path

import pytest

from jaga import stages
from jaga.fakes.spark import FakeSpark
from jaga_eval import corpus

PACK = stages.load_pack("my")


class Counting(FakeSpark):
    def __init__(self, replies=None):
        super().__init__(PACK)
        self.replies, self.calls = replies, []

    async def generate(self, rules, prompt, schema, timeout=60):
        self.calls.append((rules, prompt))
        if self.replies is None:
            return await super().generate(rules, prompt, schema)
        return self.replies.pop(0), {"input_tokens": 5, "output_tokens": 7}


def run(out, spark, limit=None):
    return asyncio.run(corpus.generate(out, spark, PACK, limit))


def test_run_writes_files_and_a_rerun_never_pays_twice(tmp_path):
    spark = Counting()
    result = run(tmp_path, spark, 3)
    assert len(spark.calls) == 3 and result["scripts"] == 3
    assert (result["tokens_in"], result["tokens_out"]) == (30, 60)
    rows = list(csv.DictReader(open(tmp_path / "manifest.csv", encoding="utf-8")))
    assert [r["id"] for r in rows] == [s["id"] for s in corpus.seeds()[:3]]
    assert {r["label"] for r in rows} <= {"scam", "genuine"}
    assert len((tmp_path / "scripts.jsonl").read_text(encoding="utf-8").splitlines()) == 3
    run(tmp_path, spark, 3)
    assert len(spark.calls) == 3


def test_invalid_reply_is_retried_once_then_skipped_and_recorded(tmp_path):
    good = json.dumps({"lines": [{"speaker": "caller", "text": "Hi", "stage": "none"}]})
    bad = json.dumps({"lines": [{"speaker": "caller", "text": "Hi", "stage": "bribery"}]})
    spark = Counting([bad, good, bad, bad])
    result = run(tmp_path, spark, 2)
    assert len(spark.calls) == 4
    assert result["skipped"] == [corpus.seeds()[1]["id"]] and result["scripts"] == 1
    cached = json.loads((tmp_path / "spark.local.json").read_text(encoding="utf-8"))
    assert cached[result["skipped"][0]]["error"]


def test_refuses_a_directory_inside_the_repo():
    with pytest.raises(ValueError, match="inside the repo"):
        run(Path(corpus.__file__).parent / "out", Counting(), 1)


def test_vocabulary_is_offered_to_scam_kinds_only():
    scam = next(s for s in corpus.seeds() if s["scam"])
    genuine = next(s for s in corpus.seeds() if not s["scam"])
    assert "akaun selamat" in corpus.prompt(scam, PACK)[1]
    assert "akaun selamat" not in corpus.prompt(genuine, PACK)[1]


def script(i, scam, stages_, hard=False, words=140):
    line = {"speaker": "caller", "text": " ".join(["kata"] * (words - 2)) + " kod TAC", "stage": "none"}
    return {
        "id": f"s{i:02d}",
        "scam": scam,
        "hard_negative": hard,
        "stages": stages_,
        "words": words,
        "lines": [line],
    }


def test_pick_reading_covers_stages_and_never_overwrites(tmp_path):
    rows = [script(i, True, [s]) for i, s in enumerate(corpus.STAGES)]
    rows += [script(10 + i, True, ["fear"]) for i in range(3)]
    rows += [script(20, False, [], hard=True), script(21, False, []), script(22, False, [])]
    rows += [script(23, True, ["money"], words=90)]
    (tmp_path / "scripts.jsonl").write_text("".join(json.dumps(r) + "\n" for r in rows), encoding="utf-8")

    ids = corpus.pick_reading(tmp_path, PACK)

    assert len(ids) == 10 and "s20" in ids and "s23" not in ids
    covered = {s for r in rows if r["id"] in ids and r["scam"] for s in r["stages"]}
    assert covered == set(corpus.STAGES)
    reading = tmp_path / "reading"
    assert (reading / "rec_10.sheet.txt").read_text(encoding="utf-8").startswith("CALLER: kata")
    assert (reading / "rec_01.ref.txt").read_text(encoding="utf-8").strip().endswith("kod TAC")
    table = list(csv.reader(open(reading / "keywords.csv", encoding="utf-8")))
    header = table[0]
    assert header[0] == "clip" and len(header) == len(set(t.lower() for t in header))
    # "kod TAC" is a longer term, so the bare "TAC" column does not count it
    assert table[1][header.index("kod tac")] == "1" and table[1][header.index("TAC")] == "0"
    (reading / "rec_01.ref.txt").write_text("mine", encoding="utf-8")
    corpus.pick_reading(tmp_path, PACK)
    assert (reading / "rec_01.ref.txt").read_text(encoding="utf-8") == "mine"
