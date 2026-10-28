"""Seam 1: scripted calls go through play_call, the bank asks Jaga Pause over HTTP."""

import json
from datetime import timedelta

import pytest
from jsonschema import Draft202012Validator
from tests.conftest import PAUSE, START
from tests.test_fake_call import CONTRACTS, media_headers, play_call, wait_for_start
from tests.test_fake_call import client as client

from jaga import telephony
from jaga.fakes.twilio import media_stream

RESPONSE = Draft202012Validator(
    json.loads((CONTRACTS / "pause.schema.json").read_text(encoding="utf-8")) | {"$ref": "#/$defs/response"},
    format_checker=Draft202012Validator.FORMAT_CHECKER,
)


def ask(client, token=PAUSE):
    reply = client.post("/pause", json={"pauseToken": token})
    if reply.status_code == 200:
        RESPONSE.validate(reply.json())
    return reply


def test_a_wrong_or_unconfigured_token_is_a_bare_404(client, clock, monkeypatch):
    wrong = ask(client, "wrong")
    assert (wrong.status_code, wrong.json()) == (404, {"detail": "Not Found"})
    monkeypatch.delenv("JAGA_PAUSE_TOKEN")
    assert ask(client, PAUSE).status_code == 404


ISOLATION = [("caller", "Jangan beritahu sesiapa ya.")]
MONEY = [("caller", "Bayar jaminan hari ini.")]


def test_a_call_that_just_ended_at_isolation_holds_for_15_minutes(client, clock):
    play_call(client, "CA_iso", ISOLATION)

    assert ask(client).json() == {
        "inScam": True,
        "stage": "isolation",
        "recommendedHoldMinutes": 15,
        "checkedAt": START.isoformat(),
    }


def test_money_holds_for_30_minutes_and_calls_below_isolation_do_not_hold(client, clock):
    play_call(client, "CA_money", MONEY)
    assert ask(client).json()["recommendedHoldMinutes"] == 30

    telephony.calls.clear()
    play_call(client, "CA_early", [("caller", "Saya Inspektor Ali dari PDRM.")])
    assert ask(client).json() == {
        "inScam": False,
        "stage": "authority",
        "recommendedHoldMinutes": 0,
        "checkedAt": START.isoformat(),
    }


def test_no_calls_is_not_in_scam(client, clock):
    assert ask(client).json() == {
        "inScam": False,
        "stage": "none",
        "recommendedHoldMinutes": 0,
        "checkedAt": START.isoformat(),
    }


def test_the_pause_holds_to_the_30_minute_mark_and_never_clears_early(client, clock):
    # The server has no dismissal path, so the user cannot clear the pause early.
    play_call(client, "CA_hold", ISOLATION)

    clock[0] = START + timedelta(minutes=29, seconds=59)
    assert ask(client).json()["inScam"] is True
    clock[0] = START + timedelta(minutes=30)
    assert ask(client).json()["inScam"] is True
    clock[0] = START + timedelta(minutes=30, seconds=1)
    after = ask(client).json()
    assert (after["inScam"], after["recommendedHoldMinutes"]) == (False, 0)


def test_the_highest_stage_across_calls_counts(client, clock):
    play_call(client, "CA_a", MONEY)
    play_call(client, "CA_b", ISOLATION)

    assert ask(client).json()["stage"] == "money"


def test_a_live_call_at_isolation_is_in_scam(client, clock):

    start, *media, _stop = media_stream("CA_live", ISOLATION, None)[1:]
    with client.websocket_connect("/twilio/media", headers=media_headers()) as twilio:
        twilio.send_text(start)
        wait_for_start("CA_live")
        with client.websocket_connect("/calls/CA_live/stages") as app_stream:
            for msg in media:
                twilio.send_text(msg)
            for _ in range(10):  # bounded, so a regression fails instead of hanging
                if app_stream.receive_json()["stage"] == "isolation":
                    break
            else:
                pytest.fail("the live call never reached isolation")
            assert ask(client).json()["inScam"] is True


@pytest.mark.parametrize(
    ("line", "stage", "hold"),
    [
        ("Sila sertai video call dengan polis.", "handoff", 15),
        ("Give me your password.", "credentials", 30),
    ],
)
def test_handoff_holds_15_and_credentials_30(client, clock, line, stage, hold):
    play_call(client, "CA_" + stage, [("caller", line)])

    answer = ask(client).json()
    assert (answer["stage"], answer["recommendedHoldMinutes"]) == (stage, hold)


def test_after_the_window_an_old_money_call_no_longer_shows_its_stage(client, clock):
    play_call(client, "CA_old", MONEY)

    clock[0] = START + timedelta(minutes=31)
    answer = ask(client).json()
    assert (answer["inScam"], answer["stage"], answer["recommendedHoldMinutes"]) == (False, "none", 0)


def test_a_call_still_at_pretext_reports_pretext_but_is_not_in_scam(client, clock):
    play_call(client, "CA_pre", [("caller", "Ada bungkusan haram atas nama puan.")])

    answer = ask(client).json()
    assert (answer["inScam"], answer["stage"]) == (False, "pretext")
