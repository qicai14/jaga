"""Day-1 telephony spike (issue #2). Throwaway: the telephony module replaces it.

A call to the Jaga line hits /twilio/voice, which forks both legs to /twilio/stream and rings the browser
Voice SDK client at /spike. /spike/report shows per-leg frame counts and connect times on one server clock.
Everything but the TwiML and the stream sits behind JAGA_SPIKE_KEY: a token lets its holder answer real calls.
"""

import base64
import hashlib
import hmac
import json
import os
import secrets
import time
from urllib.parse import parse_qs

from fastapi import APIRouter, HTTPException, Request, WebSocket
from fastapi.responses import HTMLResponse, Response

router = APIRouter()
IDENTITY = "spike"
# Media Streams tracks on the forwarded call: inbound is the caller, outbound is the answering client.
LEGS = {"inbound": "caller", "outbound": "user"}
calls: dict[str, dict] = {}


def _check_key(key: str) -> None:
    expected = os.environ.get("JAGA_SPIKE_KEY", "")
    if not expected or not secrets.compare_digest(key, expected):
        raise HTTPException(404)


def _latest() -> dict | None:
    return max(calls.values(), key=lambda c: c["webhook_at"], default=None)


@router.post("/twilio/voice")
async def voice(request: Request) -> Response:
    # parse_qs instead of request.form(), which would need python-multipart.
    call_sid = parse_qs((await request.body()).decode()).get("CallSid", [""])[0]
    calls[call_sid] = {"call_sid": call_sid, "webhook_at": time.time(), "legs": {}}
    twiml = (
        '<?xml version="1.0" encoding="UTF-8"?><Response>'
        f'<Start><Stream url="wss://{request.url.hostname}/twilio/stream" track="both_tracks"/></Start>'
        f"<Dial><Client>{IDENTITY}</Client></Dial></Response>"
    )
    return Response(twiml, media_type="text/xml")


@router.websocket("/twilio/stream")
async def stream(ws: WebSocket) -> None:
    await ws.accept()
    call = None
    async for text in ws.iter_text():
        msg = json.loads(text)
        if msg["event"] == "start":
            sid = msg["start"]["callSid"]
            call = calls.setdefault(sid, {"call_sid": sid, "webhook_at": time.time(), "legs": {}})
            call["stream_start_at"] = time.time()
            call["tracks"] = msg["start"].get("tracks")
        elif msg["event"] == "media" and call is not None:
            audio = base64.b64decode(msg["media"]["payload"])
            leg = call["legs"].setdefault(
                LEGS.get(msg["media"]["track"], msg["media"]["track"]),
                {"frames": 0, "bytes": 0, "voiced_bytes": 0, "first_at": time.time()},
            )
            leg["frames"] += 1
            leg["bytes"] += len(audio)
            # mu-law silence is 0xFF or 0x7F; anything else means someone is talking on that leg.
            leg["voiced_bytes"] += len(audio) - audio.count(b"\xff") - audio.count(b"\x7f")
        elif msg["event"] == "stop" and call is not None:
            call["stream_stop_at"] = time.time()


def access_token(now: int | None = None) -> str:
    """Voice SDK access token (Twilio's JWT format), incoming-only so a leaked one cannot place calls."""
    env = os.environ
    now = int(time.time()) if now is None else now
    header = {"typ": "JWT", "alg": "HS256", "cty": "twilio-fpa;v=1"}
    payload = {
        "jti": f"{env['TWILIO_API_KEY_SID']}-{now}",
        "iss": env["TWILIO_API_KEY_SID"],
        "sub": env["TWILIO_ACCOUNT_SID"],
        "iat": now,
        "exp": now + 3600,
        "grants": {"identity": IDENTITY, "voice": {"incoming": {"allow": True}}},
    }

    def b64(data: bytes) -> bytes:
        return base64.urlsafe_b64encode(data).rstrip(b"=")

    signing_input = b64(json.dumps(header).encode()) + b"." + b64(json.dumps(payload).encode())
    signature = hmac.new(env["TWILIO_API_KEY_SECRET"].encode(), signing_input, hashlib.sha256).digest()
    return (signing_input + b"." + b64(signature)).decode()


@router.get("/spike/token")
def token(key: str = "") -> dict[str, str]:
    _check_key(key)
    return {"token": access_token()}


@router.post("/spike/event")
def event(kind: str, key: str = "") -> dict[str, str]:
    _check_key(key)
    call = _latest()
    if call is None or kind not in ("incoming", "accepted"):
        raise HTTPException(400)
    call.setdefault(f"{kind}_at", time.time())
    return {"call_sid": call["call_sid"]}


@router.get("/spike/report")
def report(key: str = "") -> list[dict]:
    _check_key(key)
    out = []
    for call in sorted(calls.values(), key=lambda c: c["webhook_at"]):
        t0 = call["webhook_at"]
        since = {k.removesuffix("_at") + "_s": round(v - t0, 2) for k, v in call.items() if k.endswith("_at")}
        legs = {
            name: {**leg, "first_at": round(leg["first_at"] - t0, 2)} for name, leg in call["legs"].items()
        }
        out.append({"call_sid": call["call_sid"], "tracks": call.get("tracks"), **since, "legs": legs})
    return out


@router.get("/spike", response_class=HTMLResponse)
def page() -> str:
    return PAGE


PAGE = """<!doctype html><meta charset="utf-8"><title>Jaga telephony spike</title>
<script src="https://cdn.jsdelivr.net/npm/@twilio/voice-sdk@2.18.4/dist/twilio.min.js"></script>
<h1>Jaga telephony spike</h1><p id="state">Starting...</p><button id="answer" disabled>Answer</button>
<pre id="log"></pre>
<script>
const key = new URLSearchParams(location.search).get("key") || "";
const log = (m) => (document.getElementById("log").textContent += new Date().toISOString() + " " + m + "\\n");
const state = (m) => { document.getElementById("state").textContent = m; log(m); };
const mark = (kind) => fetch(`/spike/event?kind=${kind}&key=${encodeURIComponent(key)}`, {method: "POST"});
(async () => {
  const res = await fetch(`/spike/token?key=${encodeURIComponent(key)}`);
  if (!res.ok) return state("No token: open this page with ?key=<JAGA_SPIKE_KEY>");
  const device = new Twilio.Device((await res.json()).token, {closeProtection: true});
  device.on("registered", () => state("Registered as 'spike'. Call the Jaga line now."));
  device.on("error", (e) => state("Error: " + e.message));
  device.on("incoming", (call) => {
    mark("incoming");
    state("Ringing: " + call.parameters.From);
    const btn = document.getElementById("answer");
    btn.disabled = false;
    btn.onclick = () => {
      call.accept(); mark("accepted"); btn.disabled = true; state("Answered. Talk on both ends.");
    };
    call.on("disconnect", () => { btn.disabled = true; state("Call ended. See /spike/report?key=..."); });
  });
  await device.register();
})();
</script>"""
