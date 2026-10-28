import asyncio
import json

import httpx
import pytest

from jaga import spark
from jaga.spark import MuseSpark, Verdict

PACK = {"library": {"fear": {"counterMoves": [{"id": "fear-1"}, {"id": "fear-2"}]}}}
SNIPPET = "your account is frozen, pay at [number]"
ANSWER = {"stage": "fear", "risk": "high", "counterMove": "fear-1"}


def client(handler) -> MuseSpark:
    return MuseSpark(PACK, "key-123", "https://api.test/v1", transport=httpx.MockTransport(handler))


def reply(request: httpx.Request) -> httpx.Response:
    text = json.dumps(ANSWER)
    return httpx.Response(
        200, json={"output": [{"type": "message", "content": [{"type": "output_text", "text": text}]}]}
    )


def test_sends_one_standard_stateless_structured_request():
    seen = []

    def handler(request):
        seen.append(request)
        return reply(request)

    assert asyncio.run(client(handler).assess("fear", "medium", SNIPPET)) == ANSWER
    (request,) = seen
    body = json.loads(request.content)
    assert str(request.url) == "https://api.test/v1/responses"
    assert request.headers["authorization"] == "Bearer key-123"
    assert body["model"] == "muse-spark-1.3"
    assert body["store"] is False
    fmt = body["text"]["format"]
    assert fmt["type"] == "json_schema" and fmt["schema"] == Verdict.model_json_schema()


def test_snippet_only_in_the_user_item_and_counter_moves_in_the_developer_item():
    seen = []

    def handler(request):
        seen.append(json.loads(request.content))
        return reply(request)

    asyncio.run(client(handler).assess("fear", "medium", SNIPPET))
    dev, user = seen[0]["input"]
    assert (dev["role"], user["role"]) == ("developer", "user")
    assert user["content"] == [{"type": "input_text", "text": SNIPPET}]
    assert SNIPPET not in json.dumps(dev) and "fear-2" in json.dumps(dev)


@pytest.mark.parametrize(
    "response",
    [
        httpx.Response(500, json={"error": "boom"}),
        httpx.Response(200, text="not json"),
        httpx.Response(200, json={"output": []}),
        httpx.Response(200, json={"output": [{"content": [{"text": "not json"}]}]}),
    ],
)
def test_failures_raise_so_the_fail_safe_applies(response):
    with pytest.raises((httpx.HTTPError, ValueError, KeyError, IndexError)):
        asyncio.run(client(lambda request: response).assess("fear", "medium", SNIPPET))


def test_spark_is_real_without_fakes_and_needs_a_key(monkeypatch):
    monkeypatch.delenv("JAGA_USE_FAKES", raising=False)
    monkeypatch.setenv("META_API_KEY", "k")
    assert isinstance(spark.spark(PACK), MuseSpark)
    monkeypatch.delenv("META_API_KEY")
    with pytest.raises(RuntimeError):
        spark.spark(PACK)
