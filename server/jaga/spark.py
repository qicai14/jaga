"""Muse Spark: asked about the call when the rules reach a new stage from `authority` up (ADR 0005)."""

import os
from typing import Literal, Protocol

from pydantic import BaseModel, ConfigDict

MAX_CALLS = 5  # per call
TIMEOUT = 1.5  # seconds


class Verdict(BaseModel):
    """All Muse Spark may say. None of it reaches the user; counterMove is a phrase ID (ADR 0006)."""

    model_config = ConfigDict(strict=True)
    stage: Literal["pretext", "authority", "fear", "isolation", "handoff", "money", "credentials"]
    risk: Literal["low", "medium", "high"]
    counterMove: str


class Spark(Protocol):
    async def assess(self, stage: str, risk: str, snippet: str) -> dict:
        """Muse Spark's raw output for the call so far. The snippet is masked, untrusted transcript text:
        it goes in a user message, never a system prompt."""
        ...


class NoSpark:
    # shortcut: no real Spark until #21; every ask fails, so the rules' fail-safe applies.
    async def assess(self, stage: str, risk: str, snippet: str) -> dict:
        raise NotImplementedError("the Muse Spark client is #21")


def spark(pack: dict) -> Spark:
    if os.environ.get("JAGA_USE_FAKES", "").lower() == "true":
        from jaga.fakes.spark import FakeSpark

        return FakeSpark(pack)
    return NoSpark()
