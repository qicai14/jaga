"""Real FCM push for family alerts: Firebase is faked at `messaging.send_each_async`, never the network."""

import asyncio
import json
import logging
from pathlib import Path
from types import SimpleNamespace

import pytest
from firebase_admin import messaging
from jsonschema import Draft202012Validator

from jaga import alerts, fcm
from jaga.fakes.push import FakePush

CONTRACTS = Path(__file__).resolve().parents[2] / "contracts"
FAMILY_ALERT = Draft202012Validator(
    json.loads((CONTRACTS / "family-alert.schema.json").read_text(encoding="utf-8")),
    format_checker=Draft202012Validator.FORMAT_CHECKER,
)
ALERT = alerts.build("alert", "CA_fcm_1", "money", "caller: Pindahkan wang ke akaun selamat")
SECRET_TOKEN = "device-token-SECRET-1"


@pytest.fixture
def sent(monkeypatch):
    """Every (message) handed to Firebase; `fail` maps a token to the exception Firebase reports for it."""
    messages, fail = [], {}

    async def send_each_async(batch, dry_run=False, app=None):
        messages.extend(batch)
        return SimpleNamespace(responses=[SimpleNamespace(exception=fail.get(m.token)) for m in batch])

    monkeypatch.setattr(fcm.messaging, "send_each_async", send_each_async)
    monkeypatch.setattr(fcm, "_app", lambda: None)
    messages_fail = SimpleNamespace(messages=messages, fail=fail)
    return messages_fail


def test_sends_a_data_only_high_priority_message_the_app_can_parse(sent):
    asyncio.run(fcm.FcmPush().send("tok", ALERT))

    (message,) = sent.messages
    assert message.token == "tok" and message.notification is None
    assert message.android.priority == "high"
    assert list(message.data) == ["familyAlert"]
    FAMILY_ALERT.validate(json.loads(message.data["familyAlert"]))
