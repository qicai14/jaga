"""Jaga Pause: the bank asks "is this customer mid-scam?" with the protected user's pause token."""

import hmac
import os
from datetime import timedelta

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from jaga import telephony
from jaga.stages import RANK

WINDOW = timedelta(minutes=30)  # how long Jaga Pause holds after a call ends

router = APIRouter()


class Ask(BaseModel):
    pauseToken: str  # noqa: N815  (the contract's field name)


@router.post("/pause")
def pause(ask: Ask) -> dict:
    # shortcut: one protected user, one env token; upgrade with #12/#19
    token = os.environ.get("JAGA_PAUSE_TOKEN", "")
    if not token or not hmac.compare_digest(ask.pauseToken.encode(), token.encode()):
        raise HTTPException(404)
    now = telephony.now()
    calls = list(telephony.calls.values())  # in start order
    # shortcut: all calls are the one protected user's and never evicted; upgrade with #12/#19.
    counting = [
        c.tracker.stage
        for c in calls
        if RANK[c.tracker.stage] >= RANK["isolation"] and (not c.ended or now - c.ended_at <= WINDOW)
    ]
    stage = max(counting, key=RANK.get) if counting else calls[-1].tracker.stage if calls else "none"
    hold = 0 if not counting else 30 if RANK[stage] >= RANK["money"] else 15
    return {
        "inScam": bool(counting),
        "stage": stage,
        "recommendedHoldMinutes": hold,
        "checkedAt": now.isoformat(),
    }
