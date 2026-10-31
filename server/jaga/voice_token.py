"""The protected user's app fetches a Voice access token to register with Twilio (ADR 0009)."""

import hmac
import os
import time
from datetime import UTC, datetime
from typing import Annotated

import jwt
from fastapi import APIRouter, Depends, Header, HTTPException, Response

LIFETIME = 3600  # seconds; the app fetches a new token before expiresAt


def app_token(authorization: Annotated[str, Header()] = "") -> None:
    """The secret that ships in the APK. Same check as the co-pilot's, so only its holder ever sees a 503."""
    # shortcut: one shared secret in the APK, so whoever extracts it can fetch tokens for this identity (they
    # still cannot place calls); upgrade with real registration (setup, #12/#19)
    token = os.environ.get("JAGA_APP_TOKEN", "")
    if not token or not hmac.compare_digest(authorization.encode(), f"Bearer {token}".encode()):
        raise HTTPException(404)


router = APIRouter(dependencies=[Depends(app_token)])


def env(name: str) -> str:
    value = os.environ.get(name, "")
    if not value:
        raise HTTPException(503, f"{name} is not set")
    return value


@router.post("/voice-token")
async def voice_token(response: Response) -> dict:
    identity = env("JAGA_APP_CLIENT_IDENTITY")
    if os.environ.get("JAGA_USE_FAKES", "").lower() == "true":
        from jaga.fakes.twilio import FAKE_CREDENTIALS as twilio
    else:
        twilio = {
            n: env(n)
            for n in (
                "TWILIO_ACCOUNT_SID",
                "TWILIO_API_KEY_SID",
                "TWILIO_API_KEY_SECRET",
                "TWILIO_PUSH_CREDENTIAL_SID",
            )
        }
    key_sid = twilio["TWILIO_API_KEY_SID"]
    now = int(time.time())
    claims = {
        "iss": key_sid,
        "sub": twilio["TWILIO_ACCOUNT_SID"],
        "jti": f"{key_sid}-{now}",
        "exp": now + LIFETIME,
        # no outgoing grant: a leaked token cannot place calls
        "grants": {
            "identity": identity,
            "voice": {
                "incoming": {"allow": True},
                "push_credential_sid": twilio["TWILIO_PUSH_CREDENTIAL_SID"],
            },
        },
    }
    token = jwt.encode(claims, twilio["TWILIO_API_KEY_SECRET"], "HS256", {"cty": "twilio-fpa;v=1"})
    response.headers["Cache-Control"] = "no-store"
    return {"token": token, "expiresAt": datetime.fromtimestamp(claims["exp"], UTC).isoformat()}
