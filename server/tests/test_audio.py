import struct

from jaga.audio import pcm16k


def test_mulaw_8khz_becomes_16khz_pcm():
    # G.711 anchors: 0xFF is silence, 0x80 the loudest positive, 0x00 the loudest negative (+-32124).
    pcm = pcm16k(b"\xff\x80\x00")

    # Twice the samples, little-endian s16: each sample, then the midpoint to the next (the last repeats).
    assert struct.unpack("<6h", pcm) == (0, 16062, 32124, 0, -32124, -32124)


def test_empty_audio_is_empty():
    assert pcm16k(b"") == b""
