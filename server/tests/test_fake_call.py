"""Seam 1: a scripted call goes into the Twilio Media Streams WebSocket, `stage-update` messages come out."""

import json
import time
from pathlib import Path

import pytest
from fastapi.testclient import TestClient
from jsonschema import Draft202012Validator
from starlette.websockets import WebSocketDisconnect

from jaga import telephony
from jaga.fakes.transcribe import FakeTranscriber
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
def heard(monkeypatch):
    """Every (leg, line) the fake transcriber produced."""
    lines, transcribe = [], FakeTranscriber.transcribe

    async def record(self, leg, audio):
        line = await transcribe(self, leg, audio)
        lines.append((leg, line))
        return line

    monkeypatch.setattr(FakeTranscriber, "transcribe", record)
    return lines


@pytest.fixture
def client(monkeypatch):
    monkeypatch.setenv("JAGA_USE_FAKES", "true")
    # One TestClient context shares one event loop between the call's WebSocket and the app's stage stream.
    with TestClient(app) as client:
        yield client


def follow(app_stream):
    """Everything the app receives until the stage stream closes."""
    received = []
    with pytest.raises(WebSocketDisconnect):
        while True:
            received.append(app_stream.receive_json())
    return received


def wait_for_start(call_sid):
    deadline = time.monotonic() + 5
    while call_sid not in telephony.calls:
        assert time.monotonic() < deadline, "the call never started"
        time.sleep(0.01)


def play_call(client, call_sid, script, before_end=()):
    """Plays the call; the app joins its stage stream once the call starts. Returns what the app got."""
    start, *media, stop = media_stream(call_sid, script)[1:]
    with client.websocket_connect("/twilio/media") as twilio:
        twilio.send_text(start)
        wait_for_start(call_sid)
        with client.websocket_connect(f"/calls/{call_sid}/stages") as app_stream:
            for msg in [*media, *before_end, stop]:
                twilio.send_text(msg)
            return follow(app_stream)


def test_scripted_call_comes_out_as_stage_updates(client, heard):
    updates = play_call(client, "CA_fake_1", SCRIPT)

    assert heard == SCRIPT
    assert updates, "the app got no stage-update"
    for update in updates:
        STAGE_UPDATE.validate(update)
        assert update["callId"] == "CA_fake_1"
        assert (update["stage"], update["risk"]) == ("none", "low")


def test_second_start_keeps_the_call_so_the_app_still_sees_the_end(client):
    start = media_stream("CA_dup", [])[1]
    assert len(play_call(client, "CA_dup", SCRIPT, before_end=[start])) == 1


def test_malformed_message_ends_the_call(client):
    assert len(play_call(client, "CA_bad", [], before_end=["not json"])) == 1


def test_stage_stream_for_unknown_call_is_refused(client):
    with pytest.raises(WebSocketDisconnect), client.websocket_connect("/calls/CA_unknown/stages"):
        pass
