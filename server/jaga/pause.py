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
    # shortcut: all calls are the one protected user's and never evicted; upgrade with #12/#19.
    # A call is current while live (no end time) and for 30 minutes after it ends.
    # list(): this route runs in a threadpool while the loop thread adds calls.
    current = [c for c in list(telephony.calls.values()) if c.ended_at is None or now - c.ended_at <= WINDOW]
    top = max(current, key=lambda c: RANK[c.tracker.stage], default=None)
    stage = top.tracker.stage if top else "none"
    agency = telephony.claimed_agency(top.updates) if top else None  # left out when nobody claimed one
    in_scam = RANK[stage] >= RANK["isolation"]
    hold = 0 if not in_scam else 30 if RANK[stage] >= RANK["money"] else 15
    return {
        "inScam": in_scam,
        "stage": stage,
        "recommendedHoldMinutes": hold,
        "checkedAt": now.isoformat(),
    } | ({"claimedAgency": agency} if agency else {})
