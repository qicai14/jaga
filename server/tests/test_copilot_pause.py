"""Seam 1: the family co-pilot reads and clears Jaga Pause over HTTP (ADR 0010); /pause must agree."""

from contextlib import contextmanager
from types import SimpleNamespace

import pytest
from tests.conftest import PAUSE
from tests.test_fake_call import FAMILY_ALERT, alerts_of, follow, media_headers, play_call, wait_for_start
from tests.test_fake_call import client as client
from tests.test_fake_call import pushed as pushed
from tests.test_pause import ISOLATION, MONEY, PDRM_ISOLATION, RESPONSE, ask
from tests.test_timelines import AUTH, TOKEN
from tests.test_timelines import copilot as copilot

from jaga import telephony
from jaga.fakes.twilio import media_stream
from jaga.main import app

APP_TOKEN, ORIGIN = "test-app-token", "http://localhost:5000"
ROUTES = [("GET", "/copilot/pause"), ("POST", "/copilot/pause/clear")]


def read(c, headers=AUTH):
    reply = c.get("/copilot/pause", headers=headers)
    if reply.status_code == 200:
        RESPONSE.validate(reply.json())
    return reply


def clear(c, headers=AUTH):
    reply = c.post("/copilot/pause/clear", headers=headers)
    if reply.status_code == 200:
        RESPONSE.validate(reply.json())
    return reply


@contextmanager
def live(c, sid):
    """A call still going: say() sends lines and waits for the app to see `until`; finish() hangs up."""
    start, stop = media_stream(sid, [])[1:]
    with c.websocket_connect("/twilio/media", headers=media_headers()) as twilio:
        twilio.send_text(start)
        wait_for_start(sid)
        with c.websocket_connect(f"/calls/{sid}/stages") as stream:
            seen = []

            def say(*script, until):
                for msg in media_stream(sid, list(script))[2:-1]:
                    twilio.send_text(msg)
                for _ in range(10):  # bounded, so a regression fails instead of hanging
                    seen.append(stream.receive_json())
                    if seen[-1]["stage"] == until:
                        return
                pytest.fail(f"the call never reached {until}")

            def finish():
                twilio.send_text(stop)
                seen.extend(follow(stream))

            yield SimpleNamespace(say=say, finish=finish, seen=seen, stream=stream)


def test_a_clear_ends_the_pause_for_the_co_pilot_and_the_bank(copilot):
    play_call(copilot, "CA_one", MONEY)
    assert (ask(copilot).json()["inScam"], read(copilot).json()["inScam"]) == (True, True)

    cleared = clear(copilot)

    assert cleared.status_code == 200
    body = cleared.json()
    assert (body["inScam"], body["stage"], body["recommendedHoldMinutes"]) == (False, "none", 0)
    assert read(copilot).json() == ask(copilot).json() == body


def test_a_clear_is_idempotent_and_with_nothing_active_is_a_200_not_in_scam(copilot):
    first = clear(copilot)
    assert (first.status_code, first.json()["inScam"], first.json()["stage"]) == (200, False, "none")

    play_call(copilot, "CA_one", ISOLATION)
    assert clear(copilot).json() == clear(copilot).json()
    assert read(copilot).json()["inScam"] is False


@pytest.mark.parametrize(
    "headers",
    [{}, {"Authorization": "Bearer wrong"}, {"Authorization": TOKEN}, {"Authorization": "Bearer "}]
    + [{"Authorization": f"Bearer {t}"} for t in (PAUSE, APP_TOKEN)],
)
@pytest.mark.parametrize(("method", "path"), ROUTES)
def test_without_the_co_pilot_token_it_is_a_bare_404_and_the_pause_holds(copilot, method, path, headers):
    play_call(copilot, "CA_one", MONEY)

    reply = copilot.request(method, path, headers=headers)

    assert (reply.status_code, reply.json()) == (404, {"detail": "Not Found"})
    assert ask(copilot).json()["inScam"] is True


@pytest.mark.parametrize("value", [None, ""])
def test_an_unset_or_empty_co_pilot_token_never_opens_the_routes(copilot, monkeypatch, value):
    play_call(copilot, "CA_one", MONEY)
    if value is None:
        monkeypatch.delenv("JAGA_COPILOT_TOKEN")
    else:
        monkeypatch.setenv("JAGA_COPILOT_TOKEN", value)
    for headers in (AUTH, {"Authorization": "Bearer "}):
        assert read(copilot, headers).status_code == clear(copilot, headers).status_code == 404
    assert ask(copilot).json()["inScam"] is True


def test_nothing_the_protected_users_app_can_reach_clears_the_pause(copilot, monkeypatch):
    # No dismissal route exists: the one route that clears is the co-pilot's, which this token does not open.
    monkeypatch.setenv("JAGA_APP_TOKEN", APP_TOKEN)
    changing = {(m.upper(), p) for p, ops in app.openapi()["paths"].items() for m in ops if m != "get"}
    assert changing == {
        ("POST", "/twilio/voice"),
        ("POST", "/pause"),
        ("POST", "/copilot/pause/clear"),
        ("POST", "/voice-token"),
        ("DELETE", "/timelines/{call_id}"),
    }
    play_call(copilot, "CA_held", ISOLATION)
    assert clear(copilot, {"Authorization": f"Bearer {APP_TOKEN}"}).status_code == 404
    assert ask(copilot).json()["inScam"] is True


def test_a_higher_stage_after_a_clear_holds_again(copilot):
    with live(copilot, "CA_live") as call:
        call.say(*ISOLATION, until="isolation")
        clear(copilot)
        assert ask(copilot).json()["inScam"] is False

        call.say(*MONEY, until="money")

        held = ask(copilot).json()
        assert (held["inScam"], held["stage"], held["recommendedHoldMinutes"]) == (True, "money", 30)
        assert read(copilot).json() == held


def test_money_to_credentials_holds_again_though_the_rank_ties(copilot):
    with live(copilot, "CA_live") as call:
        call.say(*MONEY, until="money")
        clear(copilot)
        assert ask(copilot).json()["inScam"] is False

        call.say(
            ("user", "OTP saya 482913."), until="credentials"
        )  # only the user leg ties up to credentials

        held = ask(copilot).json()
        assert (held["inScam"], held["stage"]) == (True, "credentials")


def test_a_new_call_holds_after_a_clear(copilot):
    play_call(copilot, "CA_old", MONEY)
    clear(copilot)

    play_call(copilot, "CA_new", ISOLATION)

    assert (ask(copilot).json()["inScam"], read(copilot).json()["stage"]) == (True, "isolation")


def test_a_clear_covers_a_call_that_ended_within_the_window(copilot):
    play_call(copilot, "CA_ended", MONEY)
    assert telephony.calls["CA_ended"].ended_at is not None

    clear(copilot)

    assert ask(copilot).json()["inScam"] is False


def test_a_live_call_below_isolation_is_not_covered_and_holds_when_it_gets_there(copilot):
    with live(copilot, "CA_live") as call:
        call.say(("caller", "Saya Inspektor Ali dari PDRM."), until="authority")

        cleared = clear(copilot).json()
        assert (cleared["inScam"], cleared["stage"]) == (False, "authority")

        call.say(*ISOLATION, until="isolation")
        assert ask(copilot).json()["inScam"] is True


def test_the_most_severe_call_not_covered_is_what_the_answer_shows(copilot):
    play_call(copilot, "CA_money", MONEY)
    clear(copilot)
    play_call(copilot, "CA_pretext", [("caller", "Ada bungkusan haram atas nama puan.")])

    assert ask(copilot).json()["stage"] == read(copilot).json()["stage"] == "pretext"


def test_the_co_pilot_sees_the_claimed_agency_until_it_clears(copilot):
    play_call(copilot, "CA_pdrm_copilot", PDRM_ISOLATION)
    assert read(copilot).json()["claimedAgency"] == "PDRM"
    assert "claimedAgency" not in clear(copilot).json()


def test_the_co_pilot_routes_get_no_browser_access(copilot, monkeypatch):
    monkeypatch.setenv("DEMO_BANK_ORIGINS", ORIGIN)
    play_call(copilot, "CA_one", MONEY)
    headers = AUTH | {"Origin": ORIGIN}
    replies = [
        copilot.get("/copilot/pause", headers=headers),
        copilot.post("/copilot/pause/clear", headers=headers),
        copilot.options(
            "/copilot/pause/clear", headers={"Origin": ORIGIN, "Access-Control-Request-Method": "POST"}
        ),
    ]
    assert not any("access-control-allow-origin" in r.headers for r in replies)


def test_a_clear_leaves_tracking_alerts_and_the_timeline_alone(copilot, pushed):
    with live(copilot, "CA_live_alerts") as call:
        call.say(*ISOLATION, until="isolation")
        clear(copilot)
        call.say(*MONEY, until="money")
        call.finish()

    alerts = alerts_of(pushed)
    assert [(a["kind"], a["stage"]) for a in alerts] == [("alert", "isolation"), ("alert", "money")]
    for alert in alerts:
        FAMILY_ALERT.validate(alert)
    events = copilot.get("/timelines/CA_live_alerts", headers=AUTH).json()["events"]
    assert [(e["stage"], e["risk"], e["source"]) for e in events] == [
        (u["stage"], u["risk"], u["source"]) for u in call.seen
    ]
    assert events[-1]["stage"] == telephony.calls["CA_live_alerts"].tracker.stage == "money"


def test_the_agency_shown_is_the_one_behind_the_stage_and_never_a_cleared_calls(copilot):
    play_call(copilot, "CA_pdrm_cleared", [("caller", "Saya Inspektor Ali dari PDRM."), *MONEY])
    assert read(copilot).json()["claimedAgency"] == "PDRM"
    with live(copilot, "CA_lhdn_later") as call:
        call.say(("caller", "Saya pegawai LHDN."), until="authority")

        below = clear(copilot).json()  # covers the PDRM call only: the LHDN call is below isolation
        assert (below["inScam"], below["stage"], below["claimedAgency"]) == (False, "authority", "LHDN")

        call.say(*ISOLATION, until="isolation")
        for answer in (ask(copilot).json(), read(copilot).json()):
            assert (answer["inScam"], answer["stage"], answer["claimedAgency"]) == (True, "isolation", "LHDN")

        assert "claimedAgency" not in clear(copilot).json()
