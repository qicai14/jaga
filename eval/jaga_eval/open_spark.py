"""Eval-side Spark clients (#25): Muse Spark Open on Baseten, and a failure-counting wrapper."""

import asyncio
import json
import os

import httpx

from jaga.spark import TIMEOUT, MuseSpark, Spark, Verdict

MODEL = "meta-models/muse-spark-open-1026"


class _Captured(Exception):
    def __init__(self, body: dict):
        self.body = body


def _capture(request: httpx.Request) -> httpx.Response:
    raise _Captured(json.loads(request.content))


class OpenSpark:
    """Muse Spark Open (OpenAI-compatible chat completions). The prompt is the server's own: MuseSpark builds
    the request, we take its messages from a captured body instead of copying the text."""

    def __init__(self, pack: dict, key: str, base: str, transport: httpx.AsyncBaseTransport | None = None):
        self.prompt = MuseSpark(pack, "unused", base, httpx.MockTransport(_capture))
        self.key, self.url = key, base + "/chat/completions"
        self.http = httpx.AsyncClient(timeout=TIMEOUT, transport=transport)

    async def assess(self, stage: str, risk: str, snippet: str) -> dict:
        try:
            await self.prompt.assess(stage, risk, snippet)
        except _Captured as c:
            system, user = (m["content"][0]["text"] for m in c.body["input"])
            schema = c.body["text"]["format"]["schema"]  # the prompt names the stages only through it
        body = {
            "model": MODEL,
            "messages": [{"role": "system", "content": system}, {"role": "user", "content": user}],
            "response_format": {"type": "json_schema", "json_schema": {"name": "Verdict", "schema": schema}},
        }
        r = await self.http.post(self.url, json=body, headers={"Authorization": f"Bearer {self.key}"})
        r.raise_for_status()
        return json.loads(r.json()["choices"][0]["message"]["content"])


def open_spark(pack: dict) -> Spark:
    key, base = os.environ.get("BASETEN_API_KEY", ""), os.environ.get("BASETEN_BASE_URL", "")
    if not (key and base):
        raise RuntimeError("BASETEN_API_KEY or BASETEN_BASE_URL is not set")
    return OpenSpark(pack, key, base.rstrip("/"))


class CountingSpark:
    """Wraps a Spark client and counts what the pipeline swallows: failures, timeouts (the pipeline's own
    asyncio timeout cancels us; an httpx timeout raises), verdicts that are not a valid Verdict and a
    counterMove that is not of the stage asked about (the server treats it as Spark failing too)."""

    def __init__(self, inner: Spark, counts: dict, pack: dict):
        self.inner, self.counts, self.pack = inner, counts, pack

    async def assess(self, stage: str, risk: str, snippet: str) -> dict:
        try:
            raw = await self.inner.assess(stage, risk, snippet)
            Verdict.model_validate(raw)
            if raw["counterMove"] not in [m["id"] for m in self.pack["library"][stage]["counterMoves"]]:
                raise ValueError("counterMove is not of this stage")
            return raw
        except (asyncio.CancelledError, TimeoutError, httpx.TimeoutException):
            self.counts["failed"] += 1
            self.counts["timedOut"] += 1
            raise
        except Exception:  # noqa: BLE001 - counted by type elsewhere, never quoted
            self.counts["failed"] += 1
            raise
