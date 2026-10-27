import base64
import json

TRACKS = {"caller": "inbound", "user": "outbound"}


def media_stream(call_sid: str, script: list[tuple[str, str]]) -> list[str]:
    """Twilio Media Streams messages for a scripted call: one media chunk per (leg, line), then stop."""
    start = {"event": "start", "start": {"callSid": call_sid, "tracks": ["inbound", "outbound"]}}
    media = [
        {
            "event": "media",
            "media": {"track": TRACKS[leg], "payload": base64.b64encode(line.encode()).decode()},
        }
        for leg, line in script
    ]
    return [json.dumps(m) for m in [{"event": "connected"}, start, *media, {"event": "stop"}]]
