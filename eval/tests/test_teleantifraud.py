import json
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


@pytest.mark.parametrize(
    ("answer", "label"),
    [("不是诈骗", "normal"), ("没有诈骗", "normal"), ("no fraud", "normal"), ("not a fraud call", "normal"),
     ("非正常", "fraud"), ("非诈骗", "normal"), ("Fraud", "fraud")],
)  # fmt: skip
def test_label_negations(answer, label):
    assert t.parse_label(answer) == label


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
