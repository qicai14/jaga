class FakeTranscriber:
    """Each audio chunk is a scripted line as UTF-8 text, so a test reads like a call script."""

    async def transcribe(self, leg: str, audio: bytes) -> str | None:
        return audio.decode("utf-8", errors="replace").strip() or None
