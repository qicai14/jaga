"""Real FCM push for family alerts: Firebase is faked at `messaging.send_each_async`, never the network."""

import asyncio
import json
import logging
import time
from datetime import timedelta
from pathlib import Path
from types import SimpleNamespace

import firebase_admin
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
    monkeypatch.setattr(fcm, "_ready", lambda: None)
    return SimpleNamespace(messages=messages, fail=fail)


def test_sends_a_data_only_high_priority_message_the_app_can_parse(sent):
    asyncio.run(fcm.FcmPush().send("tok", ALERT))

    (message,) = sent.messages
    assert message.token == "tok" and message.notification is None
    assert message.android.priority == "high" and message.android.ttl == timedelta(minutes=5)
    assert list(message.data) == ["familyAlert"]
    FAMILY_ALERT.validate(json.loads(message.data["familyAlert"]))


def test_a_dead_token_fails_alone_and_the_other_family_member_is_still_alerted(sent, monkeypatch, caplog):
    sent.fail["dead-TOKEN-xyz"] = messaging.UnregisteredError(
        "requested entity not found", cause=None, http_response=None
    )
    monkeypatch.setenv("JAGA_FAMILY_TOKENS", f"dead-TOKEN-xyz,{SECRET_TOKEN}")

    with caplog.at_level(logging.WARNING):
        asyncio.run(alerts.send_all(fcm.FcmPush(), ALERT))

    assert {m.token for m in sent.messages} == {"dead-TOKEN-xyz", SECRET_TOKEN}
    assert "UnregisteredError" in caplog.text
    assert "dead-TOKEN-xyz" not in caplog.text and SECRET_TOKEN not in caplog.text
    assert "Pindahkan" not in caplog.text


def test_a_hanging_send_is_cut_by_the_push_timeout(monkeypatch, caplog):
    async def hang(batch, dry_run=False, app=None):
        await asyncio.sleep(30)

    monkeypatch.setattr(fcm.messaging, "send_each_async", hang)
    monkeypatch.setattr(fcm, "_ready", lambda: None)
    monkeypatch.setattr(alerts, "PUSH_TIMEOUT", 0.1)
    monkeypatch.setenv("JAGA_FAMILY_TOKENS", "tok")

    asyncio.run(alerts.send_all(fcm.FcmPush(), ALERT))

    assert "timed out" in caplog.text


def test_push_is_the_fake_with_fakes_fcm_with_credentials_and_none_without(monkeypatch):
    monkeypatch.setenv("JAGA_USE_FAKES", "true")
    assert isinstance(alerts.push(), FakePush)

    monkeypatch.setenv("JAGA_USE_FAKES", "false")
    monkeypatch.setenv("GOOGLE_APPLICATION_CREDENTIALS", "/secret/path/sa.json")
    assert isinstance(alerts.push(), fcm.FcmPush)

    monkeypatch.delenv("GOOGLE_APPLICATION_CREDENTIALS")
    assert alerts.push() is None


def test_a_blocking_credential_load_does_not_stall_past_the_push_timeout(monkeypatch, caplog):
    monkeypatch.setattr(fcm, "_ready", lambda: time.sleep(1))  # a sync token refresh
    monkeypatch.setattr(alerts, "PUSH_TIMEOUT", 0.1)
    monkeypatch.setenv("JAGA_FAMILY_TOKENS", "tok")

    async def timed():  # asyncio.run itself waits for the sleeping thread at shutdown, so time inside the loop
        started = time.monotonic()
        await alerts.send_all(fcm.FcmPush(), ALERT)
        return time.monotonic() - started

    assert asyncio.run(timed()) < 0.5 and "timed out" in caplog.text


def test_the_firebase_app_is_created_once(monkeypatch):
    monkeypatch.setattr(firebase_admin, "_apps", {})  # isolate from any app another test made
    first = fcm._app()
    try:
        assert fcm._app() is first
    finally:
        firebase_admin.delete_app(first)
