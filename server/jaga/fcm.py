"""Family alerts over Firebase Cloud Messaging, with the service account from the environment."""

import json

import firebase_admin
from firebase_admin import messaging


def _app() -> firebase_admin.App:
    try:
        return firebase_admin.get_app()
    except ValueError:  # not initialised yet
        return firebase_admin.initialize_app()


class FcmPush:
    async def send(self, token: str, alert: dict) -> None:
        # Data-only: the app builds its own notification. High priority wakes it on a dozing phone.
        message = messaging.Message(
            token=token,
            data={"familyAlert": json.dumps(alert)},
            android=messaging.AndroidConfig(priority="high"),
        )
        batch = await messaging.send_each_async([message], app=_app())
        if (error := batch.responses[0].exception) is not None:
            raise error  # per-message failures are returned, not raised; send_all logs the type
