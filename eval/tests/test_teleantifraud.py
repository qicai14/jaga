import json
import shutil
import wave
from pathlib import Path

import pytest

from jaga_eval import teleantifraud as t

SAMPLE = Path(__file__).parent / "fixtures" / "teleantifraud_sample.json"


def test_loader_parses_labels_and_speakers():
    calls = t.load(SAMPLE)

    assert [c.label for c in calls] == ["fraud", "normal", "fraud"]
    # two tagged speakers: the first is the caller; untagged lines are all caller leg
    assert calls[0].script == [
        ("caller", "Ada bungkusan haram atas nama puan."),
        ("user", "Apa?"),
        ("caller", "Jangan beritahu sesiapa ya."),
    ]
    assert calls[1].script == [
        ("caller", "Hello, your table is booked for seven."),
        ("caller", "See you then, thank you."),
    ]
    assert calls[2].script[1] == ("user", "谢谢。")


def test_unknown_label_fails_loudly(tmp_path):
    bad = tmp_path / "t.json"
    bad.write_text(
        json.dumps([{"prompt": [{"role": "user", "content": "x"}], "answer": "maybe"}]), encoding="utf-8"
    )
    with pytest.raises(ValueError, match="label"):
        t.load(bad)


def test_replay_predicts_fraud_on_hard_trigger_and_normal_otherwise():
    calls = t.load(SAMPLE)

    results = [t.replay(c, i) for i, c in enumerate(calls)]

    assert [(r.stage, r.predicted) for r in results] == [
        ("isolation", "fraud"),
        ("none", "normal"),
        ("none", "normal"),
    ]


def test_metrics_by_hand():
    # truth:     F F F N N N N N N N   predicted: F F N F N N N N N N
    truth = ["fraud"] * 3 + ["normal"] * 7
    pred = ["fraud", "fraud", "normal", "fraud"] + ["normal"] * 6

    m = t.metrics(truth, pred)

    assert m["confusion"] == {"fraud": {"fraud": 2, "normal": 1}, "normal": {"fraud": 1, "normal": 6}}
    assert m["fraud"] == pytest.approx({"precision": 2 / 3, "recall": 2 / 3, "f1": 2 / 3, "n": 3})
    assert m["normal"]["f1"] == pytest.approx(6 / 7)
    assert m["macro_f1"] == pytest.approx((2 / 3 + 6 / 7) / 2)
    assert m["weighted_f1"] == pytest.approx((3 * 2 / 3 + 7 * 6 / 7) / 10)


def test_bootstrap_ci_brackets_the_point_estimate():
    truth = ["fraud"] * 10 + ["normal"] * 10
    pred = ["fraud"] * 8 + ["normal"] * 12
    lo, hi = t.macro_f1_ci(truth, pred)
    assert lo <= t.metrics(truth, pred)["macro_f1"] <= hi


def test_cli_writes_local_report_and_summary_without_text(tmp_path):
    out = tmp_path / "reports"
    t.main([str(SAMPLE), "--out", str(out)])

    report = json.loads((out / "teleantifraud.local.json").read_text(encoding="utf-8"))
    assert [c["predicted"] for c in report["calls"]] == ["fraud", "normal", "normal"]
    assert set(report["calls"][0]) == {"id", "true", "predicted", "stage"}
    summary = (out / "teleantifraud.md").read_text(encoding="utf-8")
    assert "n = 3" in summary and "Apache-2.0" in summary
    assert "bungkusan" not in summary and "bungkusan" not in json.dumps(report)


@pytest.mark.parametrize("answer", ["不是诈骗", "no fraud", "Fraud", "maybe", ""])
def test_label_is_exactly_fraud_or_normal(answer):
    with pytest.raises(ValueError, match="label"):
        t.parse_label(answer)
    assert (t.parse_label("fraud"), t.parse_label("normal")) == ("fraud", "normal")


def test_file_without_transcripts_fails_loudly(tmp_path):
    # the real test.json holds one constant instruction as the text of every record, audio only
    rec = {"prompt": [{"role": "user", "content": [{"type": "text", "text": "same"}]}], "answer": "fraud"}
    f = tmp_path / "t.json"
    f.write_text(json.dumps([rec, rec]), encoding="utf-8")
    with pytest.raises(ValueError, match="no transcripts"):
        t.load(f)


def test_empty_file_and_missing_user_message_fail_loudly(tmp_path):
    f = tmp_path / "t.json"
    f.write_text("[]", encoding="utf-8")
    with pytest.raises(ValueError, match="no calls"):
        t.load(f)
    f.write_text(
        json.dumps([{"prompt": [{"role": "system", "content": "x"}], "answer": "fraud"}]), encoding="utf-8"
    )
    with pytest.raises(ValueError, match="record 0"):
        t.load(f)


def test_summary_names_input_target_and_caveat(tmp_path):
    t.main([str(SAMPLE), "--out", str(tmp_path)])
    text = (tmp_path / "teleantifraud.md").read_text(encoding="utf-8")
    assert "teleantifraud_sample.json" in text and "binary_classification/test.json" not in text
    assert "MVP target 0.75: missed" in text and "stretch 0.80: missed" in text
    assert "first tag = caller" in text


def test_default_out_is_repo_relative():
    assert t.DEFAULT_OUT.is_absolute() and t.DEFAULT_OUT.parts[-2:] == ("eval", "reports")


def fake_decode(path):
    return f"line from {Path(path).stem}".encode()  # the fake transcriber reads audio bytes as text


@pytest.fixture
def fakes(monkeypatch):
    monkeypatch.setenv("JAGA_USE_FAKES", "true")


def test_transcribe_caches_per_audio_path_limits_and_resumes(tmp_path, fakes):
    cache = tmp_path / "transcripts.local.json"

    t.transcribe(SAMPLE, tmp_path, cache, limit=1, decode=fake_decode)
    assert json.loads(cache.read_text(encoding="utf-8")) == {
        "audio/synthetic_1.wav": ["line from synthetic_1"]
    }

    def boom(path):
        raise AssertionError("already cached")

    t.transcribe(SAMPLE, tmp_path, cache, limit=1, decode=boom)  # resumes: nothing left within the limit
    t.transcribe(SAMPLE, tmp_path, cache, decode=lambda p: fake_decode(p) if "1" not in str(p) else boom(p))
    assert set(json.loads(cache.read_text(encoding="utf-8"))) == {
        f"audio/synthetic_{i}.wav" for i in (1, 2, 3)
    }


def test_loader_uses_cached_transcripts_instead_of_prompt_text():
    cache = {"audio/synthetic_2.wav": ["Ada bungkusan haram.", "Jangan beritahu sesiapa ya."]}

    calls = t.load(SAMPLE, transcripts=cache)

    assert len(calls) == 1 and calls[0].label == "normal"
    assert calls[0].script == [("caller", "Ada bungkusan haram."), ("caller", "Jangan beritahu sesiapa ya.")]


def test_replay_of_transcribed_call_and_asr_caveat(tmp_path, fakes):
    cache = tmp_path / "transcripts.local.json"
    cache.write_text(json.dumps({"audio/synthetic_2.wav": ["Jangan beritahu sesiapa ya."]}), encoding="utf-8")
    t.main([str(SAMPLE), "--transcripts", str(cache), "--out", str(tmp_path)])
    text = (tmp_path / "teleantifraud.md").read_text(encoding="utf-8")
    assert "n = 1 of 3" in text and "ASR gives no speakers" in text and "first tag = caller" not in text


@pytest.mark.skipif(shutil.which("ffmpeg") is None, reason="ffmpeg not on PATH")
def test_ffmpeg_decode_gives_8k_mulaw(tmp_path):
    wav = tmp_path / "a.wav"
    with wave.open(str(wav), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(16000)
        w.writeframes(bytes(2 * 16000))  # 1 s of silence
    assert abs(len(t.decode(wav)) - 8000) < 200
