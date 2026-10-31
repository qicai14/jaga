"""Family alerts over Firebase Cloud Messaging, with the service account from the environment."""

import asyncio
import json
from datetime import timedelta

import firebase_admin
import google.auth.transport.requests
from firebase_admin import messaging


def _app() -> firebase_admin.App:
    try:
        return firebase_admin.get_app()
    except ValueError:  # not initialised yet
        return firebase_admin.initialize_app()


def _ready() -> firebase_admin.App:
    """Blocking: loads the credential and refreshes its OAuth token, so run it off the event loop.
    firebase-admin caches both, so later sends find them valid and block on nothing."""
    app = _app()
    app.project_id  # noqa: B018 - looked up once and cached on the app
    cred = app.credential.get_credential()
    if not cred.valid:
        cred.refresh(google.auth.transport.requests.Request())
    return app


class FcmPush:
    async def send(self, token: str, alert: dict) -> None:
        # Off the loop and inside send_all's timeout, which can't interrupt a blocking call.
        app = await asyncio.to_thread(_ready)
        # token= is deprecated for fid= in firebase-admin 7.x, but it is still the FCM registration token
        # the app gives us; fid is the installation ID, so don't swap.
        # Data-only: the app builds its own notification. High priority wakes it on a dozing phone; the
        # ttl keeps a stale alert from an ended call from arriving hours later.
        message = messaging.Message(
            token=token,
            data={"familyAlert": json.dumps(alert)},
            android=messaging.AndroidConfig(priority="high", ttl=timedelta(minutes=5)),
        )
        batch = await messaging.send_each_async([message], app=app)
        if (error := batch.responses[0].exception) is not None:
            raise error  # per-message failures are returned, not raised; send_all logs the type
