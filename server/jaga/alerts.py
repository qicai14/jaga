"""Family alerts: a push to the protected user's family co-pilots about one call. A summary, never the
transcript."""

import asyncio
import logging
import os
import re
import textwrap
from datetime import UTC, datetime
from typing import Protocol

from jaga.stages import RANK

log = logging.getLogger(__name__)
MAX_TOKENS = 3  # family co-pilots per protected user
PUSH_TIMEOUT = 2.0  # seconds; a slow push must not hold up the leg's transcription and Spark
# shortcut: in memory and never evicted, single server process; keyed by call id so a reconnect's fresh Call
# keeps the count. Move to storage with the stage timeline (#16).
sent: dict[str, dict] = {}  # call id -> {"tier": highest alerted tier, "genuine": follow-up sent}


class Push(Protocol):
    async def send(self, token: str, alert: dict) -> None:
        """One FamilyAlert (contracts/family-alert.schema.json) to one family co-pilot's device."""
        ...


def push() -> Push | None:
    if os.environ.get("JAGA_USE_FAKES", "").lower() == "true":
        from jaga.fakes.push import FakePush

        return FakePush()
    if os.environ.get("GOOGLE_APPLICATION_CREDENTIALS"):
        from jaga.fcm import FcmPush

        return FcmPush()
    log.warning("GOOGLE_APPLICATION_CREDENTIALS is not set: this call sends no family alerts")
    return None


def tier(stage: str) -> int:
    """0 below isolation, 1 for isolation and handoff, 2 for money and credentials: one alert per tier."""
    return 0 if RANK[stage] < RANK["isolation"] else 1 if RANK[stage] < RANK["money"] else 2


def build(kind: str, call_id: str, stage: str, snippet: str, claimed_agency: str | None = None) -> dict:
    """snippet is the tracker's masked one; its latest lines are the quotes."""
    # shortcut: one protected user, upgrade with #12/#19
    name = os.environ.get("JAGA_PROTECTED_USER_NAME") or "Your family member"
    quotes = [
        textwrap.shorten(re.sub(r"^\w+: ", "", line), 80, placeholder="") for line in snippet.splitlines()[:2]
    ]
    summary = f"{name}'s call reached the {stage} stage of a scam script."
    if kind == "mayBeGenuine":
        summary = f"Muse Spark now thinks {name}'s call may be genuine (it was at {stage})."
    return {
        "kind": kind,
        "callId": call_id,
        "protectedUserName": name,
        "stage": stage,
        "claimedAgency": claimed_agency,
        "summary": summary[:200],
        "quotes": quotes,
        "at": datetime.now(UTC).isoformat(),
    }


async def send_all(client: Push, alert: dict) -> None:
    # shortcut: JAGA_FAMILY_TOKENS stands in for linked co-pilots, first 3 used; upgrade with #12/#19.
    tokens = [t for t in os.environ.get("JAGA_FAMILY_TOKENS", "").split(",") if t][:MAX_TOKENS]
    try:
        async with asyncio.timeout(PUSH_TIMEOUT):
            results = await asyncio.gather(*(client.send(t, alert) for t in tokens), return_exceptions=True)
    except TimeoutError:
        log.warning("call %s: family alert timed out", alert["callId"])
        return
    for e in results:
        if isinstance(e, Exception):  # type only: the message could quote a transcript. The call goes on.
            log.warning("call %s: family alert failed (%s)", alert["callId"], type(e).__name__)
