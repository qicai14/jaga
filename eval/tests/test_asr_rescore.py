import csv
import io
import json
import shutil
import wave

import pytest

from jaga_eval import asr_rescore as r


def test_normalise_makes_variants_equal():
    a = r.normalise("Erm, okay LAA! Kn you [?] pay nine ringgit?")
    assert a == "ok lah kan you pay 9 ringgit"
    assert r.normalise("sembilan mehh") == "9 meh"


def test_wer_cer_pooled_and_per_clip():
    assert r.edits(["a", "b", "c"], ["a", "x", "c", "d"]) == 2
    rows = [r.score("a b c d", "a b c e"), r.score("x y", "x y")]
    assert (rows[0].wer, rows[1].wer) == (0.25, 0.0)
    assert r.pooled(rows, "words") == 1 / 6  # 1 edit / 6 reference words
    assert r.pooled(rows, "chars") == 1 / 10  # 7 + 3 reference chars, spaces included


def test_keyword_hits_and_false_hits():
    said = {"c1": {"TAC": 2, "LHDN": 1}, "c2": {"TAC": 0, "LHDN": 0}}
    hyp = {"c1": "the tac code tac and tac", "c2": "lhdn called"}
    k = r.keyword_scores(said, hyp)
    assert k["terms"]["TAC"] == (2, 2, 1)  # said, hit, false (3 occurrences - 2 said)
    assert k["terms"]["LHDN"] == (1, 0, 1)
    assert k["hit_rate"] == 2 / 3
    assert k["false_per_call"] == (1 + 1) / 2
    assert k["go"] is False


def test_terms_from_pack_deduped():
    terms = r.pack_terms()
    assert len(terms) == len({t.lower() for t in terms})
    assert "TAC" in terms and "997" in terms


def test_merge_drops_overlap_at_seam():
    assert r.merge(["one two three four", "three four five six", "six seven"]) == (
        "one two three four five six seven"
    )
    assert r.merge(["alpha beta", "gamma delta"]) == "alpha beta gamma delta"


def test_split_chunks_with_overlap(tmp_path):
    p = tmp_path / "a.wav"
    with wave.open(str(p), "wb") as w:
        w.setnchannels(1), w.setsampwidth(2), w.setframerate(16000)
        w.writeframes(b"\0\0" * 16000 * 70)
    chunks = r.split_wav(p.read_bytes())
    sizes = []
    for c in chunks:
        with wave.open(io.BytesIO(c)) as w:
            sizes.append(w.getnframes() / 16000)
    assert sizes == [30, 30, 12]  # starts 0, 29, 58: the last runs 58..70


@pytest.mark.skipif(not shutil.which("ffmpeg"), reason="ffmpeg not installed")
def test_phone_path_gives_16k_wav(tmp_path):
    p = tmp_path / "a.wav"
    with wave.open(str(p), "wb") as w:
        w.setnchannels(1), w.setsampwidth(2), w.setframerate(44100)
        w.writeframes(b"\1\0" * 44100)
    out = r.phone_wav(p)
    with wave.open(io.BytesIO(out)) as w:
        assert (w.getframerate(), w.getnchannels(), w.getsampwidth()) == (16000, 1, 2)


def test_cli_templates_never_overwrite(tmp_path):
    (tmp_path / "call_01.mp3").write_bytes(b"x")
    (tmp_path / "call_02.mp3").write_bytes(b"x")
    (tmp_path / "call_01.ref.txt").write_text("mine")
    r.main([str(tmp_path), "--templates", "call_01", "call_02"])
    assert (tmp_path / "call_01.ref.txt").read_text() == "mine"
    assert (tmp_path / "call_02.ref.txt").exists()
    rows = list(csv.reader((tmp_path / "keywords.csv").open(encoding="utf-8")))
    assert rows[0][0] == "clip" and len(rows[0]) == 14
    assert [x[0] for x in rows[1:]] == ["call_01", "call_02"]
    before = (tmp_path / "keywords.csv").read_text()
    r.main([str(tmp_path), "--templates", "call_01"])
    assert (tmp_path / "keywords.csv").read_text() == before


def test_run_caches_muse_and_reports(tmp_path, capsys):
    (tmp_path / "call_01.mp3").write_bytes(b"x")
    (tmp_path / "call_01.ref.txt").write_text("hello TAC code")
    (tmp_path / "call_01.whisper.txt").write_text("hello tack code")
    header = ["clip", *r.pack_terms()]
    row = ["call_01"] + ["1" if t == "TAC" else "" for t in r.pack_terms()]
    with (tmp_path / "keywords.csv").open("w", newline="", encoding="utf-8") as f:
        csv.writer(f).writerows([header, row])
    calls = []

    def fake(wav, name):
        calls.append(name)
        return "hello tac code"

    r.run(tmp_path, transcribe=fake, phone=lambda p: b"wav", split=lambda b: [b])
    out = capsys.readouterr().out
    assert "| Muse |" in out and "| Whisper |" in out and "GO" in out
    assert len(calls) == 1
    assert json.loads((tmp_path / "muse.local.json").read_text())["call_01.mp3"] == "hello tac code"
    r.run(tmp_path, transcribe=fake, phone=lambda p: b"wav", split=lambda b: [b])
    assert len(calls) == 1  # cached, no second paid call


@pytest.mark.parametrize(
    "hyp,term",
    [
        ("nine nine seven", "997"),
        ("sembilan sembilan tujuh", "997"),
        ("9 9 7", "997"),
        ("L H D N", "LHDN"),
        ("L.H.D.N", "LHDN"),
    ],
)
def test_spelled_out_terms_hit(hyp, term):
    assert r.keyword_scores({"c": {term: 1}}, {"c": f"call {hyp} now"})["hit_rate"] == 1.0


def test_collapse_is_keyword_only():
    assert r.normalise("L H D N") == "l h d n"


def test_longest_term_takes_the_span():
    k = r.keyword_scores({"c": {"kod tac": 1, "TAC": 0}}, {"c": "beri kod tac"})
    assert k["terms"]["kod tac"] == (1, 1, 0)
    assert k["terms"]["TAC"] == (0, 0, 0)


def test_no_overlap_between_keywords_and_cache():
    k = r.keyword_scores({"a": {"TAC": 1}}, {"b": "tac"})
    assert k["n"] == 0 and k["go"] is False
