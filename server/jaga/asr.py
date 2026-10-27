"""Muse Voice Transcribe: turns each leg's audio into transcript lines."""

import os
from typing import Protocol


class Transcriber(Protocol):
    async def transcribe(self, leg: str, audio: bytes) -> str | None: ...


def transcriber() -> Transcriber:
    if os.environ.get("JAGA_USE_FAKES", "").lower() == "true":
        from jaga.fakes.transcribe import FakeTranscriber

        return FakeTranscriber()
    raise RuntimeError("Real Muse Voice Transcribe is not built yet (#20): set JAGA_USE_FAKES=true")
