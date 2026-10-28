"""Twilio Media Streams in (both legs of a call), the call's lifecycle, and the app's stage stream out.

A call starts on the stream's `start` event (callId = Twilio CallSid) and ends on `stop` or disconnect.
The app follows /calls/{callId}/stages: every `stage-update` so far, then live ones; closed at call end.
"""

import asyncio
import base64
import json
import logging
import os
from dataclasses import dataclass, field
from datetime import UTC, datetime
from xml.sax.saxutils import escape, quoteattr

from fastapi import APIRouter, HTTPException, Request, WebSocket, status
from fastapi.responses import Response

from jaga import alerts, asr, spark, twilio_auth
from jaga.stages import RANK, StageTracker, load_pack

router = APIRouter()
log = logging.getLogger(__name__)
# Media Streams tracks on the forwarded call: inbound is the caller, outbound is the protected user (#2).
LEGS = {"inbound": "caller", "outbound": "user"}


@dataclass
class Call:
    call_id: str
    tracker: StageTracker
    spark: spark.Spark
    sparked: int = 0
    updates: list[dict] = field(default_factory=list)
    ended: bool = False
    push: alerts.Push | None = field(default_factory=alerts.push)
    warning: bool = False  # the stage on screen is a Warning
    changed: asyncio.Condition = field(default_factory=asyncio.Condition)

    async def publish(self, stage, risk, evidence=(), command=None, counterMove=None, source="rules") -> None:
        update = {
            "callId": self.call_id,
            "stage": stage,
            "risk": risk,
            "command": command,
            "counterMove": counterMove,
            "evidence": list(evidence),
            "source": source,
        }
        async with self.changed:
            self.updates.append(update | {"at": datetime.now(UTC).isoformat()})
            self.changed.notify_all()
        await self.notify_family(update)

    async def notify_family(self, update: dict) -> None:
        """Family alerts: one on isolation or higher, one more on money or credentials, and a "may be genuine"
        follow-up the first time Muse Spark lowers a Warning after an alert."""
        lowered = self.warning and update["risk"] != "high" and update["source"] == "spark"
        self.warning = update["risk"] == "high"
        if self.push is None:
            return
        state = alerts.sent.setdefault(self.call_id, {"tier": 0, "genuine": False})
        if alerts.tier(update["stage"]) > state["tier"]:
            state["tier"], kind = alerts.tier(update["stage"]), "alert"
        elif lowered and state["tier"] and not state["genuine"]:
            kind, state["genuine"] = "mayBeGenuine", True
        else:
            return
        await alerts.send_all(
            self.push, alerts.build(kind, self.call_id, update["stage"], self.tracker.snippet())
        )

    async def end(self) -> None:
        async with self.changed:
            self.ended = True
            self.changed.notify_all()


# shortcut: in memory and never evicted, single server process; move to storage with the stage timeline (#16).
calls: dict[str, Call] = {}


@router.post("/twilio/voice")
async def voice(request: Request) -> Response:
    await twilio_auth.require_voice(request)
    # shortcut: every call is the default region's one protected user and rings one app identity, until a
    # protected-user registry (setup, #12/#19) maps the dialled number to a user.
    region = os.environ.get("JAGA_DEFAULT_REGION", "")
    identity = os.environ.get("JAGA_APP_CLIENT_IDENTITY", "")
    if not identity:
        raise HTTPException(503, "JAGA_APP_CLIENT_IDENTITY is not set")
    twiml = (
        '<?xml version="1.0" encoding="UTF-8"?><Response><Start>'
        f'<Stream url={quoteattr(twilio_auth.stream_url(request))} track="both_tracks">'
        f'<Parameter name="region" value={quoteattr(region)}/></Stream></Start>'
        f"<Dial><Client>{escape(identity)}</Client></Dial></Response>"
    )
    return Response(twiml, media_type="text/xml")


def put(queue: asyncio.Queue, item: bytes | None) -> None:
    """Queue audio, dropping the oldest when Muse falls behind (its limit is 5 s ahead of processing)."""
    # shortcut: 250 chunks is 5 s at Twilio's 20 ms; dropped audio is a gap in the transcript, not a stall.
    if queue.full():
        queue.get_nowait()
    queue.put_nowait(item)


async def hear(call: Call, leg: str, line: str) -> None:
    """The rules hear the line; a new stage from `authority` up is then put to Muse Spark."""
    before = call.tracker.stage
    change = call.tracker.hear(leg, line)
    if change:
        await call.publish(**change)
    stage, risk = asked = call.tracker.stage, call.tracker.risk
    if stage == before or RANK[stage] < RANK["authority"]:
        return
    raw = None
    if call.sparked < spark.MAX_CALLS:  # a stage past the cap is answered as if Spark failed
        call.sparked += 1
        # shortcut: this inline await holds the leg's queue up to the timeout; move Spark off the leg task
        # if audio sheds in live tests (with #21).
        try:
            async with asyncio.timeout(spark.TIMEOUT):
                raw = await call.spark.assess(stage, risk, call.tracker.snippet())
        except Exception as e:  # incl. the timeout; type only, the message could quote a transcript
            log.warning("call %s: Muse Spark failed (%s)", call.call_id, type(e).__name__)
    # The other leg may have moved the call on while Spark was thinking; Spark never heard that, so drop it.
    if (call.tracker.stage, call.tracker.risk) == asked and (change := call.tracker.spark_said(raw)):
        await call.publish(**change)


async def listen(call: Call, transcriber: asr.Transcriber, leg: str, audio: asyncio.Queue) -> None:
    """One leg's worker: transcribes its audio in order, so reading the stream never waits on Muse."""
    while (chunk := await audio.get()) is not None:
        try:
            line = await transcriber.transcribe(leg, chunk)
            if line:
                await hear(call, leg, line)
        except Exception as e:
            # Type only: the message could quote a transcript. The call goes on; this chunk is lost.
            log.warning("call %s %s leg: transcribing failed (%s)", call.call_id, leg, type(e).__name__)


@router.websocket("/twilio/media")
async def media(ws: WebSocket) -> None:
    if not twilio_auth.check(ws, {}):
        await ws.close(code=status.WS_1008_POLICY_VIOLATION)
        return
    await ws.accept()
    call, transcriber = None, None
    legs: dict[str, tuple[asyncio.Queue, asyncio.Task]] = {}
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
                    try:  # both before `calls`, so a refused call leaves nothing behind
                        client, transcriber = spark.spark(tracker.pack), asr.transcriber(tracker.pack)
                    except RuntimeError as e:  # e.g. no META_API_KEY; type only, never the message
                        log.warning("call %s refused: Meta client unavailable (%s)", sid, type(e).__name__)
                        await ws.close(code=status.WS_1011_INTERNAL_ERROR)
                        return
                    call = calls[sid] = Call(sid, tracker, client)
                    await call.publish("none", "low")
                else:
                    transcriber = asr.transcriber(call.tracker.pack)
            elif msg["event"] == "media" and call is not None:
                leg = LEGS.get(msg["media"]["track"])
                if leg is not None:
                    if leg not in legs:
                        queue = asyncio.Queue(maxsize=250)
                        legs[leg] = queue, asyncio.create_task(listen(call, transcriber, leg, queue))
                    put(legs[leg][0], base64.b64decode(msg["media"]["payload"]))
            elif msg["event"] == "stop":
                break
    except (ValueError, KeyError, TypeError):
        pass  # malformed Media Streams message: end the call below instead of a 1011 with a stack trace
    finally:
        for queue, _ in legs.values():
            put(queue, None)
        # Let queued audio finish, but not forever if Muse hangs.
        _, hung = await asyncio.wait([task for _, task in legs.values()], timeout=5) if legs else (None, ())
        for task in hung:
            task.cancel()
        try:
            if transcriber is not None:
                async with asyncio.timeout(5):  # whatever Muse does, the call still ends below
                    for leg, line in await transcriber.close():
                        await hear(call, leg, line)
        except TimeoutError:
            log.warning("call %s: Muse Voice Transcribe took too long to close", call.call_id)
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
