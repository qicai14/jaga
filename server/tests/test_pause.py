"""Seam 1: scripted calls go through play_call, the bank asks Jaga Pause over HTTP."""

import hmac
import json
from datetime import UTC, datetime, timedelta

import pytest
from jsonschema import Draft202012Validator

from jaga import telephony
from tests.test_fake_call import CONTRACTS, client, play_call  # noqa: F401  (client is a fixture)

PAUSE = "test-pause-token"
RESPONSE = Draft202012Validator(
    json.loads((CONTRACTS / "pause.schema.json").read_text(encoding="utf-8")) | {"$ref": "#/$defs/response"},
    format_checker=Draft202012Validator.FORMAT_CHECKER,
)
START = datetime(2026, 1, 1, 12, 0, tzinfo=UTC)


@pytest.fixture
def clock(monkeypatch):
    """The one clock the server reads; tests move it."""
    now = [START]
    monkeypatch.setattr(telephony, "now", lambda: now[0])
    monkeypatch.setattr(telephony, "calls", {})
    monkeypatch.setenv("JAGA_PAUSE_TOKEN", PAUSE)
    return now


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
