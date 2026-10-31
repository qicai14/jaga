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
    assert "TAC" in terms and "OTP" in terms


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


def test_stray_letters_are_not_joined():
    known = {"lhdn", "997"}
    assert r._spelled("call l h d n now", known) == "call lhdn now"
    assert r._spelled("call 9 9 7 now", known) == "call 997 now"
    assert r._spelled("a b c d", known) == "a b c d"  # not a term, left alone
    assert r.occurrences(["LHDN"], "x l h d n")["LHDN"] == 0  # stray letter in the run: no false join


def test_chinese_scores_cer_only():
    s = r.score("你好 吗", "你好吗")
    assert s.words == (0, 0) and s.chars == (0, 3)
    s = r.score("你好吗", "你好马")
    assert s.chars == (1, 3) and r.pooled([s], "words") == 0.0


def test_stages_fired_reads_the_real_tracker():
    assert r.stages_fired("Ini pegawai PDRM. Ada waran tangkap atas nama anda.") == {"authority", "fear"}
    assert r.stages_fired("selamat pagi, apa khabar") == set()


def test_stage_scores_recall_and_extras():
    s = r.stage_scores(
        {"a": {"authority", "fear"}, "b": {"money"}}, {"a": {"authority", "money"}, "b": set()}
    )
    assert s["recall"] == 1 / 3  # 1 of 3 reference stages also on Muse
    assert s["extra_per_call"] == 0.5  # money on a, not on the reference


def test_run_reports_stages_and_passes_bias(tmp_path, capsys):
    (tmp_path / "call_01.mp3").write_bytes(b"x")
    (tmp_path / "call_01.ref.txt").write_text("Ini pegawai PDRM. Ada waran tangkap.")
    (tmp_path / "call_02.mp3").write_bytes(b"x")  # no reference: stages as-is
    texts = {"call_01.mp3": "Ini pegawai PDRM.", "call_02.mp3": "Ada waran tangkap."}
    r.run(tmp_path, transcribe=lambda wav, name: texts[name], phone=lambda p: b"w", split=lambda b: [b])
    out = capsys.readouterr().out
    assert "## Stage recall" in out and "authority" in out and "fear" in out
    assert "Recall 0.500" in out and "Extra stages per call 0.50" in out


def test_bias_reaches_the_muse_request():
    import httpx

    from jaga_eval import teleantifraud as tafd

    sent = {}

    def handler(req):
        sent["body"] = req.read()
        return httpx.Response(200, json={"turns": [{"transcript": "x"}]})

    client = httpx.Client(base_url="http://t", transport=httpx.MockTransport(handler))
    tafd.batch_transcribe(b"w", "a.wav", client, bias=["Mandarin Chinese"])
    assert b'"languageBias": ["Mandarin Chinese"]' in sent["body"]


def test_stages_fired_ignores_punctuation_and_order():
    # money before authority, no punctuation: the tracker alone would report only one rise
    assert r.stages_fired("Pindahkan Wang sekarang saya pegawai PDRM") == {"money", "authority"}


def test_stages_fired_matches_in_the_trackers_form():
    assert r.stages_fired("你 有 逮 捕 令 了") == {"fear"}  # spaced CJK
    assert r.stages_fired("don’t tell anyone") == {"isolation"}  # curly apostrophe
    assert r.stages_fired("ＰＯＬＩＣＥ ＯＦＦＩＣＥＲ") == {"authority"}  # full-width Latin


def test_cjk_needs_a_mostly_chinese_reference():
    s = r.score("Encik Lim 林 minta kod tac anda sekarang juga", "Encik Lim minta kod tac anda")
    assert s.words[1] > 0


def test_keywords_override_reaches_the_muse_request():
    import httpx

    from jaga_eval import teleantifraud as tafd

    sent = []

    def handler(req):
        sent.append(req.read())
        return httpx.Response(200, json={"turns": [{"transcript": "x"}]})

    client = httpx.Client(base_url="http://t", transport=httpx.MockTransport(handler))
    tafd.batch_transcribe(b"w", "a.wav", client, keywords=["LHDN"])
    tafd.batch_transcribe(b"w", "a.wav", client, keywords=[])
    tafd.batch_transcribe(b"w", "a.wav", client)
    assert b'"keywords": ["LHDN"]' in sent[0]
    assert b'"keywords": []' in sent[1]  # empty means none, not the pack's
    assert b"OTP" in sent[2]  # default still the pack's


def test_override_uses_its_own_cache_file(tmp_path, capsys):
    (tmp_path / "call_01.mp3").write_bytes(b"x")
    (tmp_path / "muse.local.json").write_text(json.dumps({"call_01.mp3": "old"}))
    args = dict(phone=lambda p: b"w", split=lambda b: [b])
    r.run(tmp_path, transcribe=lambda w, n: "new", keywords=[], **args)
    out = capsys.readouterr().out
    caches = [p.name for p in tmp_path.glob("muse.*.local.json")]
    assert len(caches) == 1 and len(caches[0].split(".")[1]) == 8 and caches[0] in out
    assert json.loads((tmp_path / caches[0]).read_text())["call_01.mp3"] == "new"
    assert json.loads((tmp_path / "muse.local.json").read_text())["call_01.mp3"] == "old"  # untouched
    r.run(tmp_path, transcribe=lambda w, n: "x", keywords=["LHDN"], **args)
    assert len(list(tmp_path.glob("muse.*.local.json"))) == 2  # different settings, different file
    r.run(tmp_path, transcribe=lambda w, n: "x", **args)
    assert "muse.local.json" in capsys.readouterr().out
