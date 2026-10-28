"""Family co-pilot's stage timelines (ADR 0008): what is kept after a call, never the transcript or audio.

Derived from `telephony.calls`; there is no second store.
"""

import hmac
import os
from datetime import timedelta
from typing import Annotated

from fastapi import APIRouter, Depends, Header, HTTPException

from jaga import telephony

KEEP = timedelta(days=30)  # how long a timeline is kept after its call ends


def copilot(authorization: Annotated[str, Header()] = "") -> None:
    """The family co-pilot's token; the protected user's app has none. #59 reuses this."""
    # shortcut: one family, env token; upgrade with #12/#19
    token = os.environ.get("JAGA_COPILOT_TOKEN", "")
    if not token or not hmac.compare_digest(authorization.encode(), f"Bearer {token}".encode()):
        raise HTTPException(404)


router = APIRouter(prefix="/timelines", dependencies=[Depends(copilot)])


def kept() -> dict[str, telephony.Call]:
    """Calls still inside their 30 days; older ones are dropped here."""
    # shortcut: lost on Fly restart, move to Firestore with #12/#19. Eviction runs only when a timeline is
    # requested, so an unread call stays in memory past 30 days.
    now = telephony.now()
    for sid in [s for s, c in telephony.calls.items() if c.ended_at and now - c.ended_at > KEEP]:
        del telephony.calls[sid]
    return telephony.calls


def timeline(call: telephony.Call) -> dict:
    events = [{k: u[k] for k in ("at", "stage", "risk", "source", "evidence")} for u in call.updates]
    return {
        "callId": call.call_id,
        "startedAt": events[0]["at"],
        "endedAt": call.ended_at.isoformat() if call.ended_at else None,
        "events": events,
    }


@router.get("")
async def list_timelines() -> list[dict]:
    done = [timeline(c) for c in kept().values() if c.updates]
    return sorted(done, key=lambda t: t["startedAt"], reverse=True)


@router.get("/{call_id}")
async def get_timeline(call_id: str) -> dict:
    call = kept().get(call_id)
    if call is None or not call.updates:
        raise HTTPException(404)
    return timeline(call)


@router.delete("/{call_id}", status_code=204)
async def delete_timeline(call_id: str) -> None:
    call = kept().get(call_id)
    # Clear the timeline, never the Call: Jaga Pause reads `calls` and a deleted call must still hold a bank.
    if call is None or not call.updates or call.ended_at is None:
        raise HTTPException(404)
    call.updates.clear()
