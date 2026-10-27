"""Muse Voice Transcribe: turns each leg's audio into transcript lines."""

import asyncio
import json
import logging
import os
import time
from typing import Protocol

from websockets.asyncio.client import connect

from jaga.audio import pcm16k

log = logging.getLogger(__name__)


class Transcriber(Protocol):
    async def transcribe(self, leg: str, audio: bytes) -> str | None: ...

    async def close(self) -> list[tuple[str, str]]:
        """Ends the call's transcription; returns the (leg, line) pairs that finished at hangup."""
        ...


class MuseTranscriber:
    """One realtime socket per leg. Finished utterances arrive on their own schedule, so transcribe returns
    whatever has finished since the last chunk (a line shows up one 20 ms chunk late)."""

    BACKOFF = 1.5  # seconds before reopening a leg's socket after it failed
    FLUSH = 1.5  # seconds close() waits for the last utterance after sending silence

    def __init__(self, pack: dict, key: str, url: str):
        self.url, self.key = url, key
        self.hints = {"languageBias": pack["languageBias"], "keywords": pack["keywords"]}
        self.socks: dict[str, object] = {}
        self.readers: list[asyncio.Task] = []
        self.lines: dict[str, list[str]] = {}
        self.arrived: dict[str, asyncio.Event] = {}
        self.retry_at: dict[str, float] = {}

    async def transcribe(self, leg: str, audio: bytes) -> str | None:
        sock = self.socks.get(leg)
        if sock is None:
            if time.monotonic() < self.retry_at.get(leg, 0):
                return None
            try:
                sock = await self._open(leg)
            except Exception as e:
                self.retry_at[leg] = time.monotonic() + self.BACKOFF
                log.warning("Muse Voice Transcribe: opening the %s leg failed (%s)", leg, type(e).__name__)
                return None
        try:
            await sock.send(pcm16k(audio))
        except Exception as e:
            await self._drop(leg, sock, type(e).__name__)
            return None
        lines, self.lines[leg] = self.lines[leg], []
        return " ".join(lines) or None

    async def _open(self, leg: str):
        sock = await connect(self.url)
        handshake = {
            "authorization": {"accessToken": f"Bearer {self.key}"},
            "audioEncoding": "PCM_16KHZ",
            "model": "muse-voice-transcribe-1.0",
            "mode": "ENDPOINTING",
            "partialMode": "CUMULATIVE",
            "emitAudioProgress": False,
            **self.hints,
        }
        try:
            await sock.send(json.dumps(handshake))
        except BaseException:
            await asyncio.gather(sock.close(), return_exceptions=True)
            raise
        self.socks[leg] = sock
        self.lines.setdefault(leg, [])
        self.arrived.setdefault(leg, asyncio.Event())
        self.readers.append(asyncio.create_task(self._read(leg, sock)))
        return sock

    async def _drop(self, leg: str, sock, why: str) -> None:
        """Forget a failed socket (once: the reader and a send can both notice); reopen after the backoff."""
        if self.socks.get(leg) is not sock:
            return
        del self.socks[leg]
        self.retry_at[leg] = time.monotonic() + self.BACKOFF
        log.warning("Muse Voice Transcribe: the %s leg's socket failed (%s)", leg, why)
        await asyncio.gather(sock.close(), return_exceptions=True)

    async def _read(self, leg: str, sock) -> None:
        why = "closed"
        try:
            async for raw in sock:
                event = json.loads(raw)
                # ENDPOINTING marks a finished utterance with speechComplete; `final` is push-to-talk only.
                if event.get("type") == "speechComplete" and isinstance(event.get("transcript"), str):
                    self.lines[leg].append(event["transcript"])
                    self.arrived[leg].set()
                elif event.get("type") == "error":
                    why = "error event"  # no message: it could echo audio
                    break
        except Exception as e:
            why = type(e).__name__
        await self._drop(leg, sock, why)

    async def close(self) -> list[tuple[str, str]]:
        async def flush(leg: str, sock) -> list[tuple[str, str]]:
            self.arrived[leg].clear()
            try:
                # 1 s of silence makes Muse end the utterance still in progress.
                await sock.send(bytes(32000))
                await asyncio.wait_for(self.arrived[leg].wait(), self.FLUSH)
            except Exception:
                pass  # a dead socket or no more speech: take what has arrived
            lines, self.lines[leg] = self.lines[leg], []
            return [(leg, line) for line in lines]

        flushed = await asyncio.gather(*(flush(leg, sock) for leg, sock in self.socks.items()))
        for reader in self.readers:
            reader.cancel()
        await asyncio.gather(*self.readers, return_exceptions=True)
        await asyncio.gather(*(sock.close() for sock in self.socks.values()), return_exceptions=True)
        return [pair for pairs in flushed for pair in pairs]


def transcriber(pack: dict) -> Transcriber:
    if os.environ.get("JAGA_USE_FAKES", "").lower() == "true":
        from jaga.fakes.transcribe import FakeTranscriber

        return FakeTranscriber()
    key = os.environ.get("META_API_KEY", "")
    if not key:
        raise RuntimeError("META_API_KEY is not set: set it, or JAGA_USE_FAKES=true")
    base = os.environ.get("META_API_BASE_URL", "https://api.meta.ai/v1").rstrip("/")
    return MuseTranscriber(pack, key, base.replace("http", "ws", 1) + "/asr/realtime")
