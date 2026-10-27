import base64
import hashlib
import hmac
import json

import pytest
from fastapi.testclient import TestClient

from jaga import spike
from jaga.main import app

client = TestClient(app)


@pytest.fixture(autouse=True)
def env(monkeypatch):
    monkeypatch.setenv("JAGA_SPIKE_KEY", "k")
    monkeypatch.setenv("TWILIO_ACCOUNT_SID", "AC1")
    monkeypatch.setenv("TWILIO_API_KEY_SID", "SK1")
    monkeypatch.setenv("TWILIO_API_KEY_SECRET", "secret")
    spike.calls.clear()


def test_voice_forks_both_tracks_and_dials_client():
    twiml = client.post("/twilio/voice", data={"CallSid": "CA1"}).text
    assert '<Stream url="wss://testserver/twilio/stream" track="both_tracks"/>' in twiml
    assert "<Dial><Client>spike</Client></Dial>" in twiml


def test_stream_reports_both_legs():
    client.post("/twilio/voice", data={"CallSid": "CA1"})
    speech = base64.b64encode(b"\x10\x20" * 80).decode()
    with client.websocket_connect("/twilio/stream") as ws:
        ws.send_text(json.dumps({"event": "connected"}))
        ws.send_text(
            json.dumps({"event": "start", "start": {"callSid": "CA1", "tracks": ["inbound", "outbound"]}})
        )
        for track in ("inbound", "outbound", "outbound"):
            ws.send_text(json.dumps({"event": "media", "media": {"track": track, "payload": speech}}))
        ws.send_text(json.dumps({"event": "stop"}))
    client.post("/spike/event?kind=incoming&key=k")
    [call] = client.get("/spike/report?key=k").json()
    assert call["legs"]["caller"]["frames"] == 1
    assert call["legs"]["user"]["frames"] == 2
    assert call["legs"]["user"]["voiced_bytes"] == 320
    assert call["incoming_s"] >= 0


def test_key_guards_token_and_report(monkeypatch):
    assert client.get("/spike/token?key=wrong").status_code == 404
    monkeypatch.delenv("JAGA_SPIKE_KEY")
    assert client.get("/spike/report?key=").status_code == 404


def test_access_token_is_signed_incoming_only():
    head, body, sig = spike.access_token(now=1000).split(".")
    pad = lambda s: s + "=" * (-len(s) % 4)  # noqa: E731
    expected = hmac.new(b"secret", f"{head}.{body}".encode(), hashlib.sha256).digest()
    assert base64.urlsafe_b64decode(pad(sig)) == expected
    payload = json.loads(base64.urlsafe_b64decode(pad(body)))
    assert payload["iss"] == "SK1" and payload["sub"] == "AC1" and payload["exp"] == 4600
    assert payload["grants"] == {"identity": "spike", "voice": {"incoming": {"allow": True}}}
