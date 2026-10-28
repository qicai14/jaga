"""Jaga Pause: the bank asks "is this customer mid-scam?" with the protected user's pause token."""

import hmac
import os
from datetime import timedelta

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from jaga import telephony

router = APIRouter()


class Ask(BaseModel):
    pauseToken: str  # noqa: N815  (the contract's field name)


@router.post("/pause")
def pause(ask: Ask) -> dict:
    # shortcut: one protected user, one env token; upgrade with #12/#19
    token = os.environ.get("JAGA_PAUSE_TOKEN", "")
    if not token or not hmac.compare_digest(ask.pauseToken.encode(), token.encode()):
        raise HTTPException(404)
    return {"inScam": False, "checkedAt": telephony.now().isoformat()}
