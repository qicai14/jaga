"""Seam 1: scripted calls go through play_call, the family co-pilot reads stage timelines over HTTP."""

import copy

from tests.test_fake_call import client as client
from tests.test_fake_call import play_call
from tests.test_pause import clock as clock

from jaga import stages, telephony

SECRET = "rahsia-kad-hijau"
HEARD = "kad hijau dan pelanggan istimewa"  # not a pack phrase, so only the transcript could hold it
MONEY = [("caller", f"Bayar jaminan hari ini, {HEARD}."), ("user", SECRET)]


def test_evidence_masks_ic_account_and_otp_numbers(client, clock, monkeypatch):
    load = stages.load_pack

    def pack(region):
        p = copy.deepcopy(load(region))
        p["phrases"]["money"] += ["akaun 1234 5678 9012", "ic 900101-14-5678", "tac 123456"]
        return p

    monkeypatch.setattr(telephony, "load_pack", pack)
    script = [("caller", "akaun 1234 5678 9012, ic 900101-14-5678, tac 123456")]
    updates = play_call(client, "CA_mask", script)

    quotes = [q for u in updates for q in u["evidence"]]
    assert quotes and not any(c.isdigit() for q in quotes for c in q)


def test_ended_call_keeps_no_transcript_text_or_audio(client, clock):
    play_call(client, "CA_gone", MONEY)

    call = telephony.calls["CA_gone"]
    assert call.ended
    state = repr((call.updates, vars(call.tracker) | {"pack": 0}))
    assert SECRET not in state and HEARD not in state
    assert not any(isinstance(v, bytes | bytearray) for v in vars(call).values())
