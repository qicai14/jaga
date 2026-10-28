"""Seam 1: scripted calls go through play_call, the family co-pilot reads stage timelines over HTTP."""

import copy
import json
from datetime import timedelta

import pytest
from jsonschema import Draft202012Validator
from referencing import Registry, Resource
from tests import test_fake_call
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


# --- the family co-pilot's HTTP API (ADR 0008) ---

TOKEN = "test-copilot-token"
ROUTES = [("GET", "/timelines"), ("GET", "/timelines/CA_priv"), ("DELETE", "/timelines/CA_priv")]
AUTH = {"Authorization": f"Bearer {TOKEN}"}
CONTRACTS = test_fake_call.CONTRACTS
REGISTRY = Registry().with_resources(
    (s["$id"], Resource.from_contents(s))
    for s in (json.loads(p.read_text(encoding="utf-8")) for p in CONTRACTS.glob("*.schema.json"))
)


def contract(name):
    schema = json.loads((CONTRACTS / f"{name}.schema.json").read_text(encoding="utf-8"))
    return Draft202012Validator(schema, registry=REGISTRY, format_checker=Draft202012Validator.FORMAT_CHECKER)


@pytest.fixture
def copilot(client, clock, monkeypatch):
    monkeypatch.setenv("JAGA_COPILOT_TOKEN", TOKEN)
    return client


def test_a_timeline_is_valid_and_holds_no_transcript(copilot):
    play_call(copilot, "CA_one", MONEY)

    one = copilot.get("/timelines/CA_one", headers=AUTH)
    listed = copilot.get("/timelines", headers=AUTH)
    assert (one.status_code, listed.status_code) == (200, 200)
    contract("stage-timeline").validate(one.json())
    contract("stage-timeline-list").validate(listed.json())
    assert listed.json() == [one.json()]
    assert set(one.json()) <= {"callId", "startedAt", "endedAt", "claimedAgency", "events"}
    assert one.json()["endedAt"] is not None
    assert (one.json()["events"][-1]["stage"], one.json()["events"][-1]["risk"]) == ("money", "high")
    assert SECRET not in one.text + listed.text and HEARD not in one.text + listed.text


def test_the_list_is_newest_first_and_empty_when_nothing_is_kept(copilot, clock):
    assert copilot.get("/timelines", headers=AUTH).json() == []
    for sid in ("CA_old", "CA_new"):
        play_call(copilot, sid, MONEY)
        telephony.calls[sid].updates[0]["at"] = {"CA_old": "2026-01-01", "CA_new": "2026-02-01"}[sid]
    assert [t["callId"] for t in copilot.get("/timelines", headers=AUTH).json()] == ["CA_new", "CA_old"]


def test_only_the_copilot_token_gets_anything(copilot, monkeypatch):
    play_call(copilot, "CA_priv", MONEY)
    for headers in ({}, {"Authorization": "Bearer wrong"}, {"Authorization": TOKEN}):
        for method, path in [
            ("GET", "/timelines"),
            ("GET", "/timelines/CA_priv"),
            ("DELETE", "/timelines/CA_priv"),
        ]:
            assert copilot.request(method, path, headers=headers).status_code == 404
    assert "CA_priv" in telephony.calls
    monkeypatch.delenv("JAGA_COPILOT_TOKEN")
    assert copilot.get("/timelines", headers=AUTH).status_code == 404
    monkeypatch.setenv("JAGA_COPILOT_TOKEN", "")
    assert copilot.get("/timelines", headers={"Authorization": "Bearer "}).status_code == 404


def test_an_unknown_call_looks_like_a_bad_token(copilot):
    miss = copilot.get("/timelines/CA_nope", headers=AUTH)
    bad = copilot.get("/timelines/CA_nope", headers={"Authorization": "Bearer wrong"})
    assert (miss.status_code, miss.content) == (bad.status_code, bad.content) == (404, bad.content)


def test_the_copilot_can_delete_a_timeline(copilot):
    play_call(copilot, "CA_del", MONEY)

    assert copilot.delete("/timelines/CA_del", headers=AUTH).status_code == 204
    assert copilot.get("/timelines/CA_del", headers=AUTH).status_code == 404
    assert copilot.delete("/timelines/CA_del", headers=AUTH).status_code == 404


def test_a_timeline_is_kept_for_30_days_after_the_call_ends(copilot, clock):
    play_call(copilot, "CA_old", MONEY)
    ended = telephony.calls["CA_old"].ended_at
    clock[0] = ended + timedelta(days=30)
    assert copilot.get("/timelines/CA_old", headers=AUTH).status_code == 200
    clock[0] = ended + timedelta(days=30, seconds=1)
    assert copilot.get("/timelines/CA_old", headers=AUTH).status_code == 404
    assert copilot.get("/timelines", headers=AUTH).json() == []
