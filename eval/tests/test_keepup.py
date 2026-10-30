import base64
import json

from jaga_eval import keepup as k


def test_plan_streams_both_tracks_every_20ms_with_evenly_spaced_markers_ending_the_stream():
    _, ticks, markers, _ = k.plan("CA_x", "my", minutes=0.5)

    assert len(ticks) == 1500  # 30 s at 50 ticks per second
    assert [round(at, 2) for at, _ in ticks[:3]] == [0.0, 0.02, 0.04]
    for _, pair in ticks:
        assert [json.loads(m)["media"]["track"] for m in pair] == ["inbound", "outbound"]
    assert list(markers.values()) == ["pretext", "authority", "fear", "isolation", "handoff", "money"]
    at = list(markers)
    assert at[0] == 0 and at[-1] == len(ticks) - 1
    assert (
        max(b - a for a, b in zip(at, at[1:], strict=False))
        - min(b - a for a, b in zip(at, at[1:], strict=False))
        <= 1
    )
    said = json.loads(ticks[at[1]][1][0])["media"]["payload"]
    assert base64.b64decode(said).decode() == "pegawai pdrm"


def test_stats_and_verdict():
    assert k.stats([1, 2, 3, 4, 100]) == {"p50": 3, "p95": 100, "max": 100}
    ok = {"pretext": 0.3, "money": 4.9}
    assert k.verdict(ok, closed=False)
    assert not k.verdict(ok, closed=True)  # the socket closed
    assert not k.verdict({**ok, "money": None}, closed=False)  # a marker never arrived
    assert not k.verdict({**ok, "money": 5.0}, closed=False)  # the 5 s queue
