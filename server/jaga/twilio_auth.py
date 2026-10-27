"""Twilio request signatures: HMAC-SHA1 of the URL and the sorted POST params."""

import base64
import hashlib
import hmac
import os
from urllib.parse import parse_qs

from fastapi import HTTPException, Request, WebSocket


def signature(url: str, params: dict[str, list[str]], token: str) -> str:
    signed = url + "".join(k + v for k in sorted(params) for v in sorted(params[k]))
    return base64.b64encode(hmac.new(token.encode(), signed.encode(), hashlib.sha1).digest()).decode()


def valid(url: str, params: dict[str, list[str]], header: str | None, token: str) -> bool:
    # An unset token must reject everything, never sign with an empty key.
    return (
        bool(token)
        and bool(header)
        and hmac.compare_digest(signature(url, params, token).encode(), header.encode())
    )


def origin(conn: Request | WebSocket) -> str:
    # shortcut: assumes https at the public edge and no custom port; Twilio only calls https endpoints.
    return os.environ.get("JAGA_PUBLIC_URL", "").rstrip("/") or f"https://{conn.headers.get('host', '')}"


def public_url(conn: Request | WebSocket) -> str:
    """The https URL Twilio called (wss for the stream): JAGA_PUBLIC_URL's origin, else the request's Host."""
    url = origin(conn) + conn.url.path + (f"?{conn.url.query}" if conn.url.query else "")
    return url.replace("https://", "wss://", 1) if isinstance(conn, WebSocket) else url


def stream_url(conn: Request) -> str:
    return origin(conn).replace("https://", "wss://", 1) + "/twilio/media"


def check(conn: Request | WebSocket, params: dict[str, list[str]]) -> bool:
    token = os.environ.get("TWILIO_AUTH_TOKEN", "")
    return valid(public_url(conn), params, conn.headers.get("x-twilio-signature"), token)


async def require_voice(request: Request) -> None:
    """403 unless this Twilio webhook's form is signed with our auth token."""
    # parse_qs instead of request.form(), which would need python-multipart.
    params = parse_qs((await request.body()).decode(errors="replace"), keep_blank_values=True)
    if not check(request, params):
        raise HTTPException(403)
