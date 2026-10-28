"""Family alerts: a push to the protected user's family co-pilots about one call. A summary, never the
transcript."""

import logging
import os
import re
from datetime import UTC, datetime
from typing import Protocol

from jaga.stages import RANK

log = logging.getLogger(__name__)
MAX_TOKENS = 3  # family co-pilots per protected user


class Push(Protocol):
    async def send(self, token: str, alert: dict) -> None:
        """One FamilyAlert (contracts/family-alert.schema.json) to one family co-pilot's device."""
        ...


def push() -> Push | None:
    if os.environ.get("JAGA_USE_FAKES", "").lower() == "true":
        from jaga.fakes.push import FakePush

        return FakePush()
    # shortcut: no real FCM client yet, so a live call sends no family alerts; add it with the FCM
    # ticket (#12/#19).
    return None


def tier(stage: str) -> int:
    """0 below isolation, 1 for isolation and handoff, 2 for money and credentials: one alert per tier."""
    return 0 if RANK[stage] < RANK["isolation"] else 1 if RANK[stage] < RANK["money"] else 2


def alert(kind: str, call_id: str, stage: str, snippet: str) -> dict:
    """snippet is the tracker's masked one; its latest lines are the quotes."""
    name = os.environ.get(
        "JAGA_PROTECTED_USER_NAME", ""
    )  # shortcut: one protected user, upgrade with #12/#19
    quotes = [re.sub(r"^\w+: ", "", line)[:80] for line in snippet.splitlines()[:2]]
    summary = f"{name}'s call reached the {stage} stage of a scam script."
    if kind == "mayBeGenuine":
        summary = f"Muse Spark now thinks {name}'s call may be genuine (it was at {stage})."
    return {
        "kind": kind,
        "callId": call_id,
        "protectedUserName": name,
        "stage": stage,
        "claimedAgency": None,
        "summary": summary[:200],
        "quotes": quotes,
        "at": datetime.now(UTC).isoformat(),
    }


async def send_all(client: Push, alert: dict) -> None:
    # shortcut: JAGA_FAMILY_TOKENS stands in for linked co-pilots, first 3 used; upgrade with #12/#19.
    for token in [t for t in os.environ.get("JAGA_FAMILY_TOKENS", "").split(",") if t][:MAX_TOKENS]:
        try:
            await client.send(token, alert)
        except Exception as e:  # type only: the message could quote a transcript. The call goes on.
            log.warning("call %s: family alert failed (%s)", alert["callId"], type(e).__name__)
