import base64
import json

TRACKS = {"caller": "inbound", "user": "outbound"}


def media_stream(call_sid: str, script: list[tuple[str, str]], region: str | None = None) -> list[str]:
    """Twilio Media Streams messages for a scripted call: one media chunk per (leg, line), then stop."""
    start = {"event": "start", "start": {"callSid": call_sid, "tracks": ["inbound", "outbound"]}}
    if region:
        start["start"]["customParameters"] = {"region": region}
    media = [
        {
            "event": "media",
            "media": {"track": TRACKS[leg], "payload": base64.b64encode(line.encode()).decode()},
        }
        for leg, line in script
    ]
    return [json.dumps(m) for m in [{"event": "connected"}, start, *media, {"event": "stop"}]]


# Public placeholders for the fake-mode Voice access token (ADR 0009); Twilio rejects it.
FAKE_API_KEY_SECRET = "jaga-fake-api-key-secret-not-a-real-secret"
FAKE_CREDENTIALS = {
    "TWILIO_ACCOUNT_SID": "ACfake",
    "TWILIO_API_KEY_SID": "SKfake",
    "TWILIO_API_KEY_SECRET": FAKE_API_KEY_SECRET,
    "TWILIO_PUSH_CREDENTIAL_SID": "CRfake",
}
