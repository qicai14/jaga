"""Keep-up test: can a deployed server (JAGA_USE_FAKES=true, no keys) take a call's audio at line rate?

Usage: python -m jaga_eval.keepup <base url> [--minutes 5] [--out report.json] [--public-url URL]
Needs TWILIO_AUTH_TOKEN (the deployed throwaway value) in the environment; never printed. The signature URL
is --public-url / JAGA_PUBLIC_URL (what the server's own JAGA_PUBLIC_URL says), else the base URL.
Streams both Twilio tracks every 20 ms (100 messages/s) on an absolute clock, with scam-stage marker phrases
evenly spaced and the last at the end, while following /calls/{id}/stages and sampling /health every 5 s.
The fake transcriber reads each chunk as UTF-8 text, so the server's mu-law to PCM step is not exercised;
everything before it (socket, JSON, base64, the 250-chunk queue that drops the oldest) is the real call path.
Passes if every marker arrives within 2 s, the socket stays open, p95 sender slip is under 1 s and
99% of the messages were sent; the report's `failed` lists what did not hold.
"""

import argparse
import asyncio
import base64
import json
import os
import sys
import time

import httpx
from websockets.asyncio.client import connect
from websockets.exceptions import ConnectionClosed, WebSocketException

from jaga import twilio_auth
from jaga_eval.replay import CHUNK, CHUNK_SECONDS, TRACKS, audio_plan

MARKERS = {  # one phrase per stage the rules move through, from server/jaga/regions/my.json
    "pretext": "bungkusan haram",
    "authority": "pegawai pdrm",
    "fear": "waran tangkap",
    "isolation": "jangan letak telefon",
    "handoff": "sambungkan anda kepada polis",
    "money": "pindahkan wang",
}
MAX_LAG = 2  # seconds; well inside the 5 s (250 chunks) after which the server drops the oldest audio
MAX_SLIP = 1  # seconds, p95 sender slip: beyond it the test itself is not streaming at line rate
FILLER = b" " * CHUNK  # blank text: the fake transcriber hears nothing, the server still queues the chunk


def media(track: str, data: bytes) -> str:
    payload = base64.b64encode(data).decode()
    return json.dumps({"event": "media", "media": {"track": TRACKS[track], "payload": payload}})


def plan(sid: str, region: str, minutes: float):
    """(start, [(seconds in, [caller msg, user msg])], {tick: stage}, stop)."""
    start, _, stop = audio_plan(sid, {}, region)
    n = round(minutes * 60 / CHUNK_SECONDS)
    last = len(MARKERS) - 1
    markers = {round(i * (n - 1) / last): s for i, s in enumerate(MARKERS)}
    ticks = [
        (
            i * CHUNK_SECONDS,
            [
                media("caller", MARKERS[markers[i]].encode() if i in markers else FILLER),
                media("user", FILLER),
            ],
        )
        for i in range(n)
    ]
    return start, ticks, markers, stop


def stats(values: list[float]) -> dict:
    v = sorted(values)
    return {"p50": v[len(v) // 2], "p95": v[min(len(v) - 1, int(len(v) * 0.95))], "max": v[-1]} if v else {}


def verdict(
    lags: dict[str, float | None], closed: bool, slip_p95: float, sent: int, expected: int
) -> list[str]:
    """What failed; empty = pass."""
    failed = []
    if closed:
        failed.append("socket closed")
    failed += [f"marker {s} never arrived" for s, lag in lags.items() if lag is None]
    failed += [
        f"marker {s} lag {lag} s >= {MAX_LAG} s"
        for s, lag in lags.items()
        if lag is not None and lag >= MAX_LAG
    ]
    if slip_p95 > MAX_SLIP:
        failed.append(f"sender slip p95 {slip_p95:.2f} s > {MAX_SLIP} s")
    if sent < expected * 0.99:
        failed.append(f"sent {sent} of {expected} messages")
    return failed


async def wake(http: httpx.AsyncClient, base: str, limit: float = 180) -> float:
    """Seconds until /health answers its JSON body (a sleeping host may serve an HTML page with a 200)."""
    t0 = time.monotonic()
    while True:
        try:
            r = await http.get(f"{base}/health")
            if r.status_code == 200 and r.json() == {"status": "ok"}:
                return time.monotonic() - t0
        except (httpx.HTTPError, ValueError):
            pass
        if time.monotonic() - t0 > limit:
            raise SystemExit(f"{base}/health never answered within {limit:.0f} s")
        print(f"waking {base} ... {time.monotonic() - t0:.0f} s", file=sys.stderr)
        await asyncio.sleep(3)


async def sample_health(http: httpx.AsyncClient, base: str, out: list[float]) -> None:
    while True:
        await asyncio.sleep(5)
        t = time.perf_counter()
        try:
            await http.get(f"{base}/health")
            out.append(time.perf_counter() - t)
        except httpx.HTTPError:
            pass


async def follow(ws_base: str, sid: str, seen: dict[str, float]) -> None:
    """First arrival time of each stage on the stage stream."""
    for _ in range(50):  # the call exists once the server has handled `start`
        try:
            async with connect(f"{ws_base}/calls/{sid}/stages") as ws:
                async for text in ws:
                    seen.setdefault(json.loads(text)["stage"], time.monotonic())
                return
        except (OSError, WebSocketException):  # 403 until the call exists
            await asyncio.sleep(0.1)


async def run(base: str, public: str, minutes: float, token: str) -> dict:
    base = base.rstrip("/")
    ws_base = base.replace("http", "ws", 1)
    sid = f"CA_keepup_{int(time.time())}"
    start, ticks, markers, stop = plan(sid, "my", minutes)
    signed = public.rstrip("/").replace("https://", "wss://", 1) + "/twilio/media"
    headers = {"X-Twilio-Signature": twilio_auth.signature(signed, {}, token)}
    async with httpx.AsyncClient(timeout=10) as http:
        woke = await wake(http, base)
        health: list[float] = []
        seen: dict[str, float] = {}
        sent_at: dict[str, float] = {}
        slips: list[float] = []
        closed = False
        pinger = asyncio.create_task(sample_health(http, base, health))
        reader = asyncio.create_task(follow(ws_base, sid, seen))
        try:
            async with connect(f"{ws_base}/twilio/media", additional_headers=headers) as ws:
                await ws.send(json.dumps({"event": "connected"}))
                await ws.send(start)
                t0 = time.monotonic()
                for i, (offset, pair) in enumerate(ticks):
                    await asyncio.sleep(max(0.0, t0 + offset - time.monotonic()))
                    slips.append(time.monotonic() - (t0 + offset))
                    if i in markers:
                        sent_at[markers[i]] = time.monotonic()
                    for m in pair:
                        await ws.send(m)
                # the last marker is the last chunk; give its stage a few seconds to show before hanging up
                for _ in range(100):
                    if set(MARKERS) <= set(seen):
                        break
                    await asyncio.sleep(0.1)
                await ws.send(stop)
        except (ConnectionClosed, WebSocketException, OSError):
            closed = True
        pinger.cancel()
        await asyncio.wait([reader], timeout=5)
        reader.cancel()
    lags = {s: round(seen[s] - sent_at[s], 3) if s in seen and s in sent_at else None for s in MARKERS}
    failed = verdict(lags, closed, stats(slips).get("p95", 0), len(slips) * 2, len(ticks) * 2)
    return {
        "wakeSeconds": round(woke, 1),
        "messagesSent": len(slips) * 2,
        "socketClosed": closed,
        "markerLagSeconds": lags,
        "healthRoundTripMs": {k: round(v * 1000) for k, v in stats(health).items()}
        | {"samples": len(health)},
        "senderSlipMs": {k: round(v * 1000, 1) for k, v in stats(slips).items()},
        "failed": failed,
        "pass": not failed,
    }


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("base_url")
    ap.add_argument("--minutes", type=float, default=5)
    ap.add_argument("--out")
    ap.add_argument("--public-url", default=os.environ.get("JAGA_PUBLIC_URL"))
    args = ap.parse_args(argv)
    if not (token := os.environ.get("TWILIO_AUTH_TOKEN")):
        raise SystemExit("TWILIO_AUTH_TOKEN is not set")
    result = asyncio.run(run(args.base_url, args.public_url or args.base_url, args.minutes, token))
    text = json.dumps(result, indent=1)
    if args.out:
        with open(args.out, "w", encoding="utf-8") as f:
            f.write(text)
    print(text)
    raise SystemExit(0 if result["pass"] else 1)


if __name__ == "__main__":
    main()
