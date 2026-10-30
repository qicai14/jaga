import asyncio
import json

import httpx
import pytest

from jaga import stages
from jaga_eval import replay, report
from jaga_eval.open_spark import CountingSpark, OpenSpark, open_spark

SCAM = [
    ["caller", "Saya dari Bank Negara, ada bungkusan haram atas nama puan."],
    ["caller", "Jangan beritahu sesiapa, ini rahsia siasatan polis."],
    ["caller", "Pindahkan duit ke akaun selamat sekarang."],
]
GENUINE = [["caller", "Selamat pagi, ini kurier. Bungkusan anda sampai petang ini."]]


def calls_file(tmp_path, split="dev"):
    (tmp_path / "ref.txt").write_text("selamat pagi ini kurier", encoding="utf-8")
    recs = [
        {"id": "s1", "label": "scam", "split": split, "script": SCAM, "seconds": 30, "triggerAt": 0.0},
        {
            "id": "g1",
            "label": "genuine",
            "split": split,
            "script": GENUINE,
            "seconds": 3600,
            "reference": "ref.txt",
        },
        {"id": "h1", "label": "scam", "split": "heldout", "script": SCAM, "seconds": 30},
    ]
    path = tmp_path / "calls.json"
    path.write_text(json.dumps(recs), encoding="utf-8")
    return path


def test_arms_metrics_and_markdown(tmp_path, monkeypatch):
    monkeypatch.setitem(report.SPARK_FOR_ARM, "rules+spark", "fake")
    calls = [c for c in replay.load(calls_file(tmp_path)) if c.split == "dev"]
    labels = {c.id: c.label for c in calls}
    results = {}
    for arm in ("rules", "rules+spark", "spark-only"):
        monkeypatch.setenv("JAGA_USE_FAKES", "true")
        reps = report.run_arm(calls, arm, "fake", 0)
        results[arm] = report.metrics(reps, labels, spark_usd=0.01, asr_usd_per_min=0.0)
    assert results["rules"]["spark_asked"] == 0  # Spark off
    assert results["rules+spark"]["spark_asked"] > 0
    assert results["rules"]["scam_n"] == 1 and results["rules"]["genuine_n"] == 1
    assert results["rules"]["false_alarms"] == 0 and results["rules"]["genuine_hours"] == 1.0
    assert results["rules"]["wer_ci"] is not None and results["rules"]["wer"] is not None
    assert results["spark-only"]["spark_failed"] == 0 and results["spark-only"]["spark_asked"] == 4
    text = report.markdown(results, "dev", "calls.json")
    assert "## spark-only" in text and "Scams caught before `money`" in text


def test_caught_needs_a_warning_before_money():
    up = lambda stage, risk: {"stage": stage, "risk": risk}  # noqa: E731
    assert report.caught({"updates": [up("fear", "medium"), up("isolation", "high"), up("money", "high")]})
    assert not report.caught({"updates": [up("money", "high")]})  # the money line raised it: too late
    assert not report.caught({"updates": [up("fear", "medium")]})


def test_open_spark_speaks_chat_completions_with_the_servers_prompt():
    seen = {}

    def handler(req):
        seen["url"], seen["body"] = str(req.url), json.loads(req.content)
        verdict = {"stage": "fear", "risk": "medium", "counterMove": "x"}
        return httpx.Response(200, json={"choices": [{"message": {"content": json.dumps(verdict)}}]})

    pack = stages.load_pack("my")
    client = OpenSpark(pack, "k", "https://baseten.test/v1", httpx.MockTransport(handler))
    assert asyncio.run(client.assess("fear", "medium", "snippet"))["stage"] == "fear"
    assert seen["url"] == "https://baseten.test/v1/chat/completions"
    assert seen["body"]["model"] == "meta-models/muse-spark-open-1026"
    assert [m["role"] for m in seen["body"]["messages"]] == ["system", "user"]
    assert "'money'" in seen["body"]["messages"][0]["content"]  # the schema is not enforced on this model
    assert seen["body"]["messages"][1]["content"] == "snippet"
    fmt = seen["body"]["response_format"]
    assert fmt["type"] == "json_schema" and fmt["json_schema"]["name"] == "Verdict"
    assert (
        "money" in fmt["json_schema"]["schema"]["properties"]["stage"]["enum"]
    )  # the model learns the stages


def test_open_spark_needs_its_keys(monkeypatch):
    monkeypatch.delenv("BASETEN_API_KEY", raising=False)
    with pytest.raises(RuntimeError):
        open_spark({})


def test_counting_spark_counts_what_the_pipeline_swallows():
    pack = stages.load_pack("my")
    good = {"stage": "fear", "risk": "low", "counterMove": pack["library"]["fear"]["counterMoves"][0]["id"]}
    other_stage = pack["library"]["money"]["counterMoves"][0]["id"]

    class Inner:
        def __init__(self, act):
            self.act = act

        async def assess(self, *a):
            return await self.act()

    async def hang():
        await asyncio.sleep(10)

    async def httpx_timeout():
        raise httpx.ReadTimeout("slow")

    async def boom():
        raise RuntimeError("down")

    async def bad():
        return {"stage": "nonsense"}

    async def wrong_stage_move():
        return good | {"counterMove": other_stage}

    async def fine():
        return good

    async def run(act):
        counts = {"failed": 0, "timedOut": 0}
        try:
            async with asyncio.timeout(0.01):
                await CountingSpark(Inner(act), counts, pack).assess("fear", "low", "x")
        except Exception:  # noqa: BLE001
            pass
        return counts

    cases = [
        (hang, 1, 1),
        (httpx_timeout, 1, 1),
        (boom, 1, 0),
        (bad, 1, 0),
        (wrong_stage_move, 1, 0),
        (fine, 0, 0),
    ]
    for act, failed, timed_out in cases:
        assert asyncio.run(run(act)) == {"failed": failed, "timedOut": timed_out}


def test_heldout_needs_final(tmp_path):
    with pytest.raises(SystemExit, match="final"):
        report.main([str(calls_file(tmp_path)), "--split", "heldout", "--out", str(tmp_path)])


def up(stage, risk):
    return {"stage": stage, "risk": risk}


def rep(id, updates, ttw=None, seconds=3600, warned=None):
    return {
        "id": id,
        "audioSeconds": seconds,
        "firstWarningAt": warned,
        "updates": updates,
        "ttw": ttw,
        "spark": {"asked": 2, "failed": 1, "timedOut": 1},
    }


def test_metrics_from_hand_built_reports():
    warn = [up("fear", "medium"), up("isolation", "high"), up("money", "high")]
    reps = [
        rep("s1", warn, ttw=1.5, seconds=60, warned=2.0),
        rep("s2", warn, ttw=-0.5, seconds=60, warned=0.5),  # Warning before the trigger line
        rep("s3", [up("money", "high")], ttw=0.2, seconds=60, warned=0.2),  # late: not caught
        rep("g1", [up("fear", "high")], seconds=3600, warned=5.0),  # false alarm
        rep("g2", [up("fear", "medium")], seconds=3600),  # Caution only
        rep("g3", [up("none", "low")], seconds=3600),
    ]
    labels = {"s1": "scam", "s2": "scam", "s3": "scam", "g1": "genuine", "g2": "genuine", "g3": "genuine"}
    m = report.metrics(reps, labels, spark_usd=0.01, asr_usd_per_min=0.1)

    assert (m["scam_n"], m["genuine_n"], m["missed"]) == (3, 3, 1)
    assert m["caught"] == pytest.approx(2 / 3)
    assert m["false_alarms"] == 1 and m["genuine_cautions"] == 1  # the Caution is not a false alarm
    assert m["false_per_10h"] == pytest.approx(10 / 3)
    assert (m["ttw_n"], m["ttw_early"]) == (2, 1)
    assert m["p50"] == 1.5 and m["p95"] == 1.5  # sorted [0.0, 1.5], int(q * 2) = 1
    assert (m["spark_asked"], m["spark_failed"], m["spark_timed_out"]) == (12, 6, 6)
    assert m["cost_per_call"] == pytest.approx((2 * 0.01 * 6 + (3 * 60 + 3 * 3600) / 60 * 0.1) / 6)
    assert report.metrics(reps, labels)["cost_per_call"] is None  # no prices given: not guessed


def test_zero_false_alarms_gives_the_rule_of_three():
    reps = [rep("g1", [up("none", "low")], seconds=7200)]
    m = report.metrics(reps, {"g1": "genuine"})
    assert m["false_per_10h"] == 0.0 and m["false_ci"] == (0.0, 15.0)  # 30 / 2 h


@pytest.mark.parametrize(
    ("xs", "q", "want"),
    [([], 0.5, None), ([5], 0.95, 5), ([4, 1, 3, 2], 0.5, 3), ([4, 1, 3, 2], 0.95, 4)],
)
def test_quantile(xs, q, want):
    assert report.quantile(xs, q) == want


def test_ci_is_a_seeded_percentile_bootstrap():
    mean = lambda s: sum(s) / len(s)  # noqa: E731
    assert report.ci([], mean) is None
    assert report.ci([2, 2, 2], mean) == (2, 2)
    lo, hi = report.ci([0, 1] * 10, mean)
    assert report.ci([0, 1] * 10, mean) == (lo, hi) and 0 < lo < 0.5 < hi < 1


@pytest.mark.parametrize(
    ("value", "higher", "span", "want"),
    [
        (None, True, None, "not measured"),
        (0.96, True, (0.91, 0.99), "met MVP and stretch"),
        (0.92, True, (0.91, 0.97), "met MVP, missed stretch"),
        (0.85, True, (0.8, 0.97), "missed (CI spans the target)"),
        (0.85, True, (0.8, 0.88), "missed"),
        (0.0, False, None, "met MVP and stretch"),
    ],
)
def test_verdict(value, higher, span, want):
    target, stretch = (0.90, 0.95) if higher else (1.0, 0.0)
    assert report.verdict(value, target, stretch, higher, span) == want


def test_arms_are_checked_before_any_run(tmp_path, monkeypatch):
    for k in ("META_API_KEY", "BASETEN_API_KEY", "BASETEN_BASE_URL", "JAGA_USE_FAKES"):
        monkeypatch.delenv(k, raising=False)
    calls = [replay.Call("a", audio={"caller": tmp_path / "x.wav"}, label="scam")]
    with pytest.raises(SystemExit, match="script"):
        report.check_arms(calls, ["spark-only"], "fake")
    with pytest.raises(SystemExit, match="BASETEN"):
        report.check_arms(calls, ["rules+open"], "muse")
    with pytest.raises(SystemExit, match="META_API_KEY"):
        report.check_arms(calls, ["rules"], "muse")
    monkeypatch.setenv("META_API_KEY", "k")
    report.check_arms(calls, ["rules"], "muse")


def test_heldout_report_is_never_overwritten(tmp_path, monkeypatch):
    monkeypatch.setenv("JAGA_USE_FAKES", "true")
    (tmp_path / "metrics-heldout.md").write_text("first run", encoding="utf-8")
    path = calls_file(tmp_path)
    args = [str(path), "--split", "heldout", "--final", "--arms", "spark-only", "--out", str(tmp_path)]
    with pytest.raises(SystemExit, match="never overwrite"):
        report.main(args)
    assert (tmp_path / "metrics-heldout.md").read_text(encoding="utf-8") == "first run"


class Recording:
    """A Spark client that notes the loop and snippet of each ask."""

    def __init__(self):
        self.loops, self.snippets = [], []

    async def assess(self, stage, risk, snippet):
        self.loops.append(asyncio.get_running_loop())
        self.snippets.append(snippet)
        return {"stage": "pretext", "risk": "low", "counterMove": "x"}


def spark_only(monkeypatch, calls):
    client = Recording()
    monkeypatch.setattr(report.spark_module, "spark", lambda pack: client)
    report.run_arm(calls, "spark-only", "fake", 0)
    return client


def test_spark_only_runs_every_call_in_one_event_loop(monkeypatch):
    calls = [replay.Call(f"c{i}", script=[("caller", "Helo")], seconds=10) for i in range(2)]
    assert len(set(spark_only(monkeypatch, calls).loops)) == 1


def test_spark_only_masks_a_number_split_across_lines(monkeypatch):
    calls = [replay.Call("c", script=[("caller", "kod 123"), ("caller", "456 ya")], seconds=10)]
    assert spark_only(monkeypatch, calls).snippets[-1] == "kod [number] ya"


def test_a_row_with_a_bad_split_is_refused_not_dropped(tmp_path):
    path = calls_file(tmp_path)
    recs = json.loads(path.read_text(encoding="utf-8"))
    recs.append({"id": "t1", "label": "scam", "split": "heldoutt", "script": SCAM, "seconds": 30})
    path.write_text(json.dumps(recs), encoding="utf-8")
    with pytest.raises(SystemExit, match="split"):
        report.main([str(path), "--out", str(tmp_path)])


def test_spark_only_p95_has_no_target_verdict():
    m = report.metrics([rep("s", [up("fear", "high")], ttw=1.0, seconds=60, warned=1.0)], {"s": "scam"})
    text = report.markdown({"rules": m, "spark-only": m}, "dev", "c.json")
    p95 = [ln for ln in text.split("## spark-only")[1:] for ln in ln.splitlines() if "p95" in ln]
    assert p95 and "met" not in p95[0] and "missed" not in p95[0]
    assert "met MVP" in next(ln for ln in text.split("## spark-only")[0].splitlines() if "p95" in ln)


def test_script_calls_need_seconds_when_played_from_the_script(tmp_path, monkeypatch):
    monkeypatch.setenv("JAGA_USE_FAKES", "true")
    calls = [replay.Call("a", script=[("caller", "x")], label="scam")]
    for arm, transcriber in [("spark-only", "fake"), ("rules", "fake")]:
        with pytest.raises(SystemExit, match="seconds"):
            report.check_arms(calls, [arm], transcriber)
    calls[0].seconds = 5
    report.check_arms(calls, ["spark-only", "rules"], "fake")


def test_wer_is_not_measured_without_reference_words():
    reps = [rep("g", [up("none", "low")]) | {"asr": {"words": [0, 0], "chars": [2, 10]}}]
    m = report.metrics(reps, {"g": "genuine"})
    assert (m["wer"], m["wer_ci"]) == (None, None) and m["cer"] == pytest.approx(0.2)


def test_open_arm_cost_uses_its_own_price(tmp_path, monkeypatch):
    monkeypatch.setattr(replay, "open_spark", replay.FakeSpark)
    monkeypatch.setenv("BASETEN_API_KEY", "k")
    monkeypatch.setenv("BASETEN_BASE_URL", "https://b.test")
    cost = {}
    for name, extra in [("without", []), ("with", ["--open-usd", "0.02"])]:
        args = [
            str(calls_file(tmp_path)),
            "--arms",
            "rules+open",
            "--spark-usd",
            "0.5",
            "--asr-usd-per-min",
            "0",
        ]
        report.main([*args, *extra, "--out", str(tmp_path / name)])
        text = (tmp_path / name / "metrics-dev.md").read_text(encoding="utf-8")
        cost[name] = next(ln for ln in text.splitlines() if ln.startswith("| Cost per call"))
    assert "n/a" in cost["without"].split("|")[3]
    assert "n/a" not in cost["with"].split("|")[3] and "0.5" not in cost["with"].split("|")[3]


def test_the_report_states_how_caught_is_graded(tmp_path):
    m = report.metrics([rep("s", [up("fear", "high")], seconds=60, warned=1.0)], {"s": "scam"})
    text = " ".join(report.markdown({"rules": m}, "dev", "c.json").split())
    assert "behaves as if Spark failed" in text and "not a labelled line" in text
