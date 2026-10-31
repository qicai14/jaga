"""Jaga Pause: the bank asks "is this customer mid-scam?" with the protected user's pause token."""

import hmac
import os
from datetime import timedelta

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from jaga import telephony
from jaga.stages import RANK
from jaga.timelines import copilot

WINDOW = timedelta(minutes=30)  # how long Jaga Pause holds after a call ends

router = APIRouter()
copilot_router = APIRouter(prefix="/copilot/pause", dependencies=[Depends(copilot)])


class Ask(BaseModel):
    pauseToken: str  # noqa: N815  (the contract's field name)


def current(now) -> list[telephony.Call]:
    """Calls live or ended within the window. list(): routes run in a threadpool while the loop adds calls."""
    # shortcut: all calls are the one protected user's and never evicted; upgrade with #12/#19.
    return [c for c in list(telephony.calls.values()) if c.ended_at is None or now - c.ended_at <= WINDOW]


def state() -> dict:
    """One answer for the bank and the co-pilot. A call cleared at its current stage no longer counts."""
    now = telephony.now()
    held = [c for c in current(now) if c.cleared_stage != c.tracker.stage]
    top = max(held, key=lambda c: RANK[c.tracker.stage], default=None)
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


@router.post("/pause")
def pause(ask: Ask) -> dict:
    # shortcut: one protected user, one env token; upgrade with #12/#19
    token = os.environ.get("JAGA_PAUSE_TOKEN", "")
    if not token or not hmac.compare_digest(ask.pauseToken.encode(), token.encode()):
        raise HTTPException(404)
    return state()


@copilot_router.get("")
def copilot_state() -> dict:
    return state()


@copilot_router.post("/clear")
def copilot_clear() -> dict:
    """Covers the calls holding the pause now; a later stage change on one holds it again."""
    for c in current(telephony.now()):
        if RANK[c.tracker.stage] >= RANK["isolation"]:
            c.cleared_stage = c.tracker.stage
    return state()
