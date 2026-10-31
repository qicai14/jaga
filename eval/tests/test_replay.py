import asyncio
import base64
import json
import math
import shutil
import struct
import time
import wave

import pytest

from jaga import spark
from jaga.fakes.spark import FakeSpark
from jaga_eval import replay as r

SCRIPT = [
    ["caller", "Saya dari Bank Negara, ada bungkusan haram atas nama puan."],
    ["caller", "Jangan beritahu sesiapa, ini rahsia siasatan polis."],
    ["user", "Baik."],
]


def write_calls(tmp_path, calls):
    path = tmp_path / "calls.json"
    path.write_text(json.dumps(calls), encoding="utf-8")
    return path


def test_fake_replay_records_updates_alerts_and_timings(tmp_path):
    calls = r.load(write_calls(tmp_path, [{"id": "scam-1", "script": SCRIPT}]))

    rep = r.replay(calls[0], 0, "fake", "fake", speed=0)

    assert rep["id"] == "scam-1"
    assert rep["updates"][0]["stage"] == "none"  # every call opens with a stage-update
    assert rep["finalStage"] == "isolation"
    assert rep["updates"][-1]["stage"] == rep["finalStage"]
    assert [u["at"] for u in rep["updates"]] == sorted(u["at"] for u in rep["updates"])
    assert set(rep["stageFirstAt"]) == {u["stage"] for u in rep["updates"]}
    assert [a["kind"] for a in rep["familyAlerts"]] == ["alert"]
    assert rep["heard"]["caller"]["lines"] == 2 and rep["heard"]["user"]["lines"] == 1
    assert rep["endedAt"] >= rep["streamedAt"]


def test_genuine_call_ends_at_none_with_no_alert(tmp_path):
    script = [["caller", "Selamat pagi, ini kurier. Bungkusan anda sampai petang ini."]]
    calls = r.load(write_calls(tmp_path, [{"id": "courier", "script": script}]))

    rep = r.replay(calls[0], 1, "fake", "fake", speed=0)

    assert (rep["finalStage"], rep["familyAlerts"], rep["firstWarningAt"]) == ("none", [], None)


def test_pacing_streams_at_real_time_speed(tmp_path):
    calls = r.load(write_calls(tmp_path, [{"id": "paced", "script": SCRIPT}]))  # 3 chunks = 40 ms apart

    start = time.monotonic()
    r.replay(calls[0], 2, "fake", "fake", speed=0.2)  # 5x slower: the last chunk goes at 0.04 / 0.2 s
    paced = time.monotonic() - start

    assert paced >= 0.2


def test_audio_plan_chunks_to_20ms_and_interleaves_legs():
    caller, user = bytes([0xFF]) * 480, bytes([0x7F]) * 320  # 60 ms and 40 ms of mu-law

    start, media, stop = r.audio_plan("CA1", {"caller": caller, "user": user}, "my")

    assert json.loads(start)["start"]["customParameters"] == {"region": "my"}
    assert json.loads(stop) == {"event": "stop"}
    seen = []
    for t, m in media:
        media_msg = json.loads(m)["media"]
        seen.append((round(t, 2), media_msg["track"], len(base64.b64decode(media_msg["payload"]))))
    assert seen == [
        (0.0, "inbound", 160),
        (0.0, "outbound", 160),
        (0.02, "inbound", 160),
        (0.02, "outbound", 160),
        (0.04, "inbound", 160),
    ]


@pytest.mark.skipif(shutil.which("ffmpeg") is None, reason="needs ffmpeg")
def test_recording_becomes_8khz_mulaw(tmp_path):
    wav = tmp_path / "a.wav"
    with wave.open(str(wav), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(16000)
        w.writeframes(
            b"".join(struct.pack("<h", int(8000 * math.sin(i / 5))) for i in range(16000))  # 1 s
        )

    assert len(r.mulaw(wav)) == 8000


def test_muse_needs_audio_and_fake_needs_a_script(tmp_path):
    only_script, only_audio = r.Call("s", script=[("caller", "x")]), r.Call("a", audio={"caller": tmp_path})

    with pytest.raises(ValueError, match="needs audio"):
        r.replay(only_script, 0, "muse", "fake", 0)
    with pytest.raises(ValueError, match="needs a script"):
        r.replay(only_audio, 0, "fake", "fake", 0)


def test_load_rejects_empty_and_unknown_legs(tmp_path):
    with pytest.raises(ValueError, match="neither"):
        r.load(write_calls(tmp_path, [{"id": "x"}]))
    with pytest.raises(ValueError, match="leg"):
        r.load(write_calls(tmp_path, [{"id": "x", "audio": {"agent": "a.wav"}}]))


MONEY = [["caller", "Sila pindahkan wang ke akaun ini."]]  # money at a Caution: only Spark raises the Warning


def test_a_warning_is_stamped_when_it_arrives_not_when_the_reader_began_waiting(tmp_path, monkeypatch):
    class Slow(FakeSpark):
        async def assess(self, *a):
            await asyncio.sleep(0.3)
            return await super().assess(*a)

    monkeypatch.setattr(r, "FakeSpark", Slow)
    calls = r.load(write_calls(tmp_path, [{"id": "slow", "script": MONEY}]))

    rep = r.replay(calls[0], 0, "fake", "fake", speed=0)

    assert rep["firstWarningAt"] >= 0.25


def test_each_replay_builds_its_own_http_client(tmp_path, monkeypatch):
    seen = []

    class Watching(FakeSpark):
        def __init__(self, pack):
            seen.append(spark._http)
            super().__init__(pack)

    monkeypatch.setattr(r, "FakeSpark", Watching)
    monkeypatch.setattr(spark, "_http", "left by an earlier event loop")
    calls = r.load(write_calls(tmp_path, [{"id": "x", "script": SCRIPT}]))

    r.replay(calls[0], 0, "fake", "fake", speed=0)

    assert seen == [None]


def test_a_second_replay_of_the_same_index_gets_its_own_family_alert(tmp_path):
    calls = r.load(write_calls(tmp_path, [{"id": "scam-1", "script": SCRIPT}]))

    first = r.replay(calls[0], 0, "fake", "fake", speed=0)
    second = r.replay(calls[0], 0, "fake", "fake", speed=0)

    assert [a["kind"] for a in first["familyAlerts"]] == ["alert"]
    assert [a["kind"] for a in second["familyAlerts"]] == ["alert"]


def test_a_row_without_a_split_keeps_it_empty(tmp_path):
    assert r.load(write_calls(tmp_path, [{"id": "x", "script": SCRIPT}]))[0].split == ""


def test_replay_main_refuses_held_out_rows(tmp_path):
    path = write_calls(tmp_path, [{"id": "x", "script": SCRIPT, "split": "heldout"}])
    with pytest.raises(SystemExit, match="report"):
        r.main([str(path), "--out", str(tmp_path)])
