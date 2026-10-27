"""Seam 1: a scripted call goes into the Twilio Media Streams WebSocket, `stage-update` messages come out."""

import json
from pathlib import Path

import pytest
from fastapi.testclient import TestClient
from jsonschema import Draft202012Validator
from starlette.websockets import WebSocketDisconnect

from jaga.fakes.twilio import media_stream
from jaga.main import app

CONTRACTS = Path(__file__).resolve().parents[2] / "contracts"
STAGE_UPDATE = Draft202012Validator(
    json.loads((CONTRACTS / "stage-update.schema.json").read_text(encoding="utf-8")),
    format_checker=Draft202012Validator.FORMAT_CHECKER,
)

SCRIPT = [
    ("caller", "Hello, saya dari Pos Malaysia. Ada bungkusan untuk puan."),
    ("user", "Bungkusan apa?"),
    ("caller", "Bungkusan dari Shopee, boleh sahkan alamat?"),
]


@pytest.fixture
def client(monkeypatch):
    monkeypatch.setenv("JAGA_USE_FAKES", "true")
    # One TestClient context shares one event loop between the call's WebSocket and the app's stage stream.
    with TestClient(app) as client:
        yield client


def play_call(client, call_sid, script):
    """Plays the call; the app joins its stage stream once the call starts. Returns what the app got."""
    start, *rest = media_stream(call_sid, script)[1:]
    with client.websocket_connect("/twilio/media") as twilio:
        twilio.send_text(start)
        with client.websocket_connect(f"/calls/{call_sid}/stages") as app_stream:
            for msg in rest:
                twilio.send_text(msg)
            received = []
            with pytest.raises(WebSocketDisconnect):
                while True:
                    received.append(app_stream.receive_json())
    return received


def test_scripted_call_comes_out_as_stage_updates(client):
    updates = play_call(client, "CA_fake_1", SCRIPT)

    assert updates, "the app got no stage-update"
    for update in updates:
        STAGE_UPDATE.validate(update)
        assert update["callId"] == "CA_fake_1"
        assert (update["stage"], update["risk"]) == ("none", "low")


def test_stage_stream_for_unknown_call_is_refused(client):
    with pytest.raises(WebSocketDisconnect), client.websocket_connect("/calls/CA_unknown/stages"):
        pass
