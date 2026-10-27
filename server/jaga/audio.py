"""Twilio's 8 kHz G.711 mu-law to the 16 kHz signed 16-bit little-endian PCM Muse Voice Transcribe takes."""

import struct


def _decode(byte: int) -> int:
    u = ~byte & 0xFF
    sample = (((u & 0x0F) << 3) + 0x84 << ((u >> 4) & 7)) - 0x84
    return -sample if u & 0x80 else sample


_TABLE = [_decode(b) for b in range(256)]


def pcm16k(mulaw: bytes) -> bytes:
    samples = [_TABLE[b] for b in mulaw]
    # shortcut: linear interpolation per chunk, the last sample repeats at each 20 ms chunk edge; upgrade
    # to a filtered resampler if the eval shows chunk-edge artefacts hurting recognition.
    nxt = [*samples[1:], samples[-1]] if samples else []
    out = [v for a, b in zip(samples, nxt, strict=True) for v in (a, (a + b) // 2)]
    return struct.pack(f"<{len(out)}h", *out)
