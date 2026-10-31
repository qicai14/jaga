"""Seam: the protected user's app fetches a Voice access token over HTTP (ADR 0009). Tokens are minted at runtime."""

import json
import logging
from datetime import datetime
from pathlib import Path

import jwt
import pytest
from fastapi.testclient import TestClient
from jsonschema import Draft202012Validator

from jaga.main import app

APP_TOKEN = "test-app-token"
SECRET = "test-api-key-secret-0123456789abcdef"  # HS256 wants 32+ bytes
CONFIG = {
    "JAGA_APP_TOKEN": APP_TOKEN,
    "JAGA_APP_CLIENT_IDENTITY": "test-identity",
    "TWILIO_ACCOUNT_SID": "ACtest",
    "TWILIO_API_KEY_SID": "SKtest",
    "TWILIO_API_KEY_SECRET": SECRET,
    "TWILIO_PUSH_CREDENTIAL_SID": "CRtest",
}
AUTH = {"Authorization": f"Bearer {APP_TOKEN}"}
SCHEMA = json.loads(
    (Path(__file__).parents[2] / "contracts" / "voice-token.schema.json").read_text(encoding="utf-8")
)


@pytest.fixture
def configured(monkeypatch):
    for k, v in CONFIG.items():
        monkeypatch.setenv(k, v)
    monkeypatch.delenv("JAGA_USE_FAKES", raising=False)


@pytest.fixture
def client():
    return TestClient(app)


def decode(body, key=SECRET):
    return jwt.decode(body["token"], key, algorithms=["HS256"], options={"verify_aud": False})


@pytest.mark.parametrize("headers", [{}, {"Authorization": "Bearer nope"}, {"Authorization": "Bearer "}])
def test_without_the_app_token_the_route_is_a_bare_404(client, configured, headers):
    r = client.post("/voice-token", headers=headers)
    assert r.status_code == 404
    assert APP_TOKEN not in r.text


@pytest.mark.parametrize("value", [None, ""])
def test_an_unset_or_empty_app_token_never_matches(client, configured, monkeypatch, value):
    monkeypatch.delenv("JAGA_APP_TOKEN") if value is None else monkeypatch.setenv("JAGA_APP_TOKEN", value)
    monkeypatch.delenv("TWILIO_API_KEY_SECRET")  # a 503 here would mean config was checked before the secret
    assert client.post("/voice-token", headers={"Authorization": "Bearer "}).status_code == 404
    assert client.post("/voice-token", headers=AUTH).status_code == 404


def test_the_body_is_the_contract_and_is_never_cached(client, configured):
    r = client.post("/voice-token", headers=AUTH)
    assert r.status_code == 200
    Draft202012Validator(SCHEMA, format_checker=Draft202012Validator.FORMAT_CHECKER).validate(r.json())
    assert r.headers["cache-control"] == "no-store"


def test_the_token_is_a_twilio_voice_incoming_grant(client, configured):
    r = client.post("/voice-token?identity=evil", json={"identity": "evil"}, headers=AUTH)
    body = r.json()
    claims = decode(body)
    header = jwt.get_unverified_header(body["token"])
    assert (header["alg"], header["cty"]) == ("HS256", "twilio-fpa;v=1")
    assert (claims["iss"], claims["sub"]) == ("SKtest", "ACtest")
    assert claims["jti"].startswith("SKtest-")
    assert claims["exp"] - int(claims["jti"].removeprefix("SKtest-")) == 3600
    assert datetime.fromisoformat(body["expiresAt"]).timestamp() == claims["exp"]
    assert claims["grants"] == {
        "identity": "test-identity",
        "voice": {"incoming": {"allow": True}, "push_credential_sid": "CRtest"},
    }


@pytest.mark.parametrize("name", [n for n in CONFIG if n != "JAGA_APP_TOKEN"])
def test_each_missing_config_is_a_503_naming_it(client, configured, monkeypatch, name):
    monkeypatch.delenv(name)
    r = client.post("/voice-token", headers=AUTH)
    assert (r.status_code, r.json()["detail"]) == (503, f"{name} is not set")
    assert SECRET not in r.text


def test_fakes_sign_with_placeholders_and_ignore_real_twilio_values(client, configured, monkeypatch):
    monkeypatch.setenv("JAGA_USE_FAKES", "true")
    from jaga.fakes.twilio import FAKE_API_KEY_SECRET

    body = client.post("/voice-token", headers=AUTH).json()
    claims = decode(body, FAKE_API_KEY_SECRET)
    assert (claims["iss"], claims["sub"]) == ("SKfake", "ACfake")
    assert claims["grants"]["voice"]["push_credential_sid"] == "CRfake"
    assert claims["grants"]["identity"] == "test-identity"
    with pytest.raises(jwt.InvalidSignatureError):
        decode(body)


def test_fakes_need_no_twilio_vars_but_keep_the_404_and_identity_503(client, monkeypatch):
    monkeypatch.setenv("JAGA_USE_FAKES", "true")
    for name in CONFIG:
        monkeypatch.delenv(name, raising=False)
    monkeypatch.setenv("JAGA_APP_TOKEN", APP_TOKEN)
    r = client.post("/voice-token", headers=AUTH)
    assert (r.status_code, r.json()["detail"]) == (503, "JAGA_APP_CLIENT_IDENTITY is not set")
    assert client.post("/voice-token").status_code == 404
    monkeypatch.setenv("JAGA_APP_CLIENT_IDENTITY", "test-identity")
    assert client.post("/voice-token", headers=AUTH).status_code == 200


def test_no_secret_or_token_reaches_the_logs(client, configured, caplog):
    caplog.set_level(logging.DEBUG)
    body = client.post("/voice-token", headers=AUTH).json()
    client.post("/voice-token", headers={"Authorization": "Bearer nope"})
    assert body["token"] not in caplog.text
    assert SECRET not in caplog.text
    assert APP_TOKEN not in caplog.text
