"""Demo Bank CORS: only POST /pause (and its preflight) answers a browser on a listed origin."""

import pytest
from fastapi.testclient import TestClient
from tests.conftest import PAUSE

from jaga.main import app

BANK = "http://localhost:5000"


@pytest.fixture
def client():
    return TestClient(app)


def preflight(client, origin=BANK, path="/pause"):
    return client.options(
        path,
        headers={
            "Origin": origin,
            "Access-Control-Request-Method": "POST",
            "Access-Control-Request-Headers": "content-type",
        },
    )


def test_a_listed_origin_gets_the_allow_headers(client, monkeypatch):
    monkeypatch.setenv("DEMO_BANK_ORIGINS", f"https://other.example, {BANK}")
    reply = preflight(client)
    assert reply.status_code == 200
    assert reply.headers["access-control-allow-origin"] == BANK
    assert "POST" in reply.headers["access-control-allow-methods"]
    assert "content-type" in reply.headers["access-control-allow-headers"].lower()
    assert "access-control-allow-credentials" not in reply.headers


def test_an_unlisted_origin_is_refused(client, monkeypatch):
    monkeypatch.setenv("DEMO_BANK_ORIGINS", BANK)
    reply = preflight(client, origin="http://evil.example")
    assert reply.status_code == 400
    assert "access-control-allow-origin" not in reply.headers


@pytest.mark.parametrize("value", [None, "", " , "])
def test_unset_or_empty_means_no_cors(client, monkeypatch, value):
    monkeypatch.delenv("DEMO_BANK_ORIGINS", raising=False)
    if value is not None:
        monkeypatch.setenv("DEMO_BANK_ORIGINS", value)
    assert "access-control-allow-origin" not in preflight(client).headers


def test_other_routes_get_no_cors_headers(client, monkeypatch):
    monkeypatch.setenv("DEMO_BANK_ORIGINS", BANK)
    reply = client.get("/health", headers={"Origin": BANK})
    assert reply.status_code == 200
    assert "access-control-allow-origin" not in reply.headers
    assert "access-control-allow-origin" not in preflight(client, path="/health").headers


def test_pause_itself_is_unchanged(client, clock, monkeypatch):
    monkeypatch.setenv("DEMO_BANK_ORIGINS", BANK)
    ok = client.post("/pause", json={"pauseToken": PAUSE}, headers={"Origin": BANK})
    assert ok.status_code == 200
    assert ok.json()["stage"] == "none"
    assert ok.headers["access-control-allow-origin"] == BANK
    bad = client.post("/pause", json={"pauseToken": "wrong"}, headers={"Origin": BANK})
    assert (bad.status_code, bad.json()) == (404, {"detail": "Not Found"})
