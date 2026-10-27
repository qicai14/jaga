"""Muse Voice Transcribe: turns each leg's audio into transcript lines."""

import asyncio
import json
import logging
import os
from typing import Protocol

from websockets.asyncio.client import connect

from jaga.audio import pcm16k

log = logging.getLogger(__name__)


class Transcriber(Protocol):
    async def transcribe(self, leg: str, audio: bytes) -> str | None: ...

    async def close(self) -> None: ...


class MuseTranscriber:
    """One realtime socket per leg. Finished utterances arrive on their own schedule, so transcribe returns
    whatever has finished since the last chunk (a line shows up one 20 ms chunk late)."""

    def __init__(self, pack: dict, key: str, url: str):
        self.url, self.key = url, key
        self.hints = {"languageBias": pack["languageBias"], "keywords": pack["keywords"]}
        self.socks: dict[str, object] = {}
        self.readers: list[asyncio.Task] = []
        self.lines: dict[str, list[str]] = {}

    async def transcribe(self, leg: str, audio: bytes) -> str | None:
        if leg not in self.socks:
            await self._open(leg)
        await self.socks[leg].send(pcm16k(audio))
        lines, self.lines[leg] = self.lines[leg], []
        return " ".join(lines) or None

    async def _open(self, leg: str) -> None:
        sock = await connect(self.url)
        await sock.send(
            json.dumps(
                {
                    "authorization": {"accessToken": f"Bearer {self.key}"},
                    "audioEncoding": "PCM_16KHZ",
                    "model": "muse-voice-transcribe-1.0",
                    "mode": "ENDPOINTING",
                    "partialMode": "CUMULATIVE",
                    "emitAudioProgress": False,
                    **self.hints,
                }
            )
        )
        self.socks[leg], self.lines[leg] = sock, []
        self.readers.append(asyncio.create_task(self._read(leg, sock)))

    async def _read(self, leg: str, sock) -> None:
        try:
            async for raw in sock:
                event = json.loads(raw)
                if (
                    event.get("type") == "transcript"
                    and event.get("final")
                    and isinstance(event.get("transcript"), str)
                ):
                    self.lines[leg].append(event["transcript"])
                elif event.get("type") == "error":
                    log.warning(
                        "Muse Voice Transcribe error on the %s leg", leg
                    )  # message left out on purpose
        except Exception as e:
            log.warning("Muse Voice Transcribe socket for the %s leg ended (%s)", leg, type(e).__name__)

    async def close(self) -> None:
        for reader in self.readers:
            reader.cancel()
        for sock in self.socks.values():
            await sock.close()


def transcriber(pack: dict) -> Transcriber:
    if os.environ.get("JAGA_USE_FAKES", "").lower() == "true":
        from jaga.fakes.transcribe import FakeTranscriber

        return FakeTranscriber()
    key = os.environ.get("META_API_KEY", "")
    if not key:
        raise RuntimeError("META_API_KEY is not set: set it, or JAGA_USE_FAKES=true")
    base = os.environ.get("META_API_BASE_URL", "https://api.meta.ai/v1").rstrip("/")
    return MuseTranscriber(pack, key, base.replace("http", "ws", 1) + "/asr/realtime")
