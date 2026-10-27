"""Twilio Media Streams in (both legs of a call), the call's lifecycle, and the app's stage stream out.

A call starts on the stream's `start` event (callId = Twilio CallSid) and ends on `stop` or disconnect.
The app follows /calls/{callId}/stages: every `stage-update` so far, then live ones; closed at call end.
"""

import asyncio
import base64
import json
import logging
from dataclasses import dataclass, field
from datetime import UTC, datetime

from fastapi import APIRouter, WebSocket, status

from jaga import asr
from jaga.stages import StageTracker, load_pack

router = APIRouter()
log = logging.getLogger(__name__)
# Media Streams tracks on the forwarded call: inbound is the caller, outbound is the protected user (#2).
LEGS = {"inbound": "caller", "outbound": "user"}


@dataclass
class Call:
    call_id: str
    tracker: StageTracker
    updates: list[dict] = field(default_factory=list)
    ended: bool = False
    changed: asyncio.Condition = field(default_factory=asyncio.Condition)

    async def publish(self, stage, risk, evidence=(), command=None, counterMove=None) -> None:
        update = {
            "callId": self.call_id,
            "stage": stage,
            "risk": risk,
            "command": command,
            "counterMove": counterMove,
            "evidence": list(evidence),
            "source": "rules",
        }
        async with self.changed:
            self.updates.append(update | {"at": datetime.now(UTC).isoformat()})
            self.changed.notify_all()

    async def end(self) -> None:
        async with self.changed:
            self.ended = True
            self.changed.notify_all()


# shortcut: in memory and never evicted, single server process; move to storage with the stage timeline (#16).
calls: dict[str, Call] = {}


@router.websocket("/twilio/media")
async def media(ws: WebSocket) -> None:
    await ws.accept()
    transcriber = asr.transcriber()
    call = None
    try:
        async for text in ws.iter_text():
            msg = json.loads(text)
            if msg["event"] == "start" and call is None:
                sid = msg["start"]["callSid"]
                call = calls.get(sid)
                # A reconnect keeps a live call's Call, so stage clients following it still get the end.
                if call is None or call.ended:
                    region = msg["start"].get("customParameters", {}).get("region")
                    try:
                        tracker = StageTracker(load_pack(region))
                    except ValueError as e:
                        log.warning("call %s refused: %s", sid, e)
                        await ws.close(code=status.WS_1008_POLICY_VIOLATION)
                        return
                    call = calls[sid] = Call(sid, tracker)
                    await call.publish("none", "low")
            elif msg["event"] == "media" and call is not None:
                leg = LEGS.get(msg["media"]["track"])
                if leg is not None:
                    line = await transcriber.transcribe(leg, base64.b64decode(msg["media"]["payload"]))
                    change = call.tracker.hear(leg, line) if line else None
                    if change:
                        await call.publish(**change)
            elif msg["event"] == "stop":
                break
    except (ValueError, KeyError, TypeError):
        pass  # malformed Media Streams message: end the call below instead of a 1011 with a stack trace
    finally:
        if call is not None:
            await call.end()


@router.websocket("/calls/{call_id}/stages")
async def stages(ws: WebSocket, call_id: str) -> None:
    # shortcut: no auth, anyone with a CallSid can follow its stages; add with the app pairing (#12/#19).
    call = calls.get(call_id)
    if call is None:
        await ws.close(code=status.WS_1008_POLICY_VIOLATION)
        return
    await ws.accept()
    sent = 0
    while True:
        # shortcut: a client that leaves mid-call is noticed only on the next send; fine at a few per call.
        async with call.changed:
            await call.changed.wait_for(lambda n=sent: len(call.updates) > n or call.ended)
            new, sent, ended = call.updates[sent:], len(call.updates), call.ended
        for update in new:
            await ws.send_json(update)
        if ended:
            break
    await ws.close()
