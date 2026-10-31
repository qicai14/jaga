"""Send one real family alert through FcmPush to JAGA_TEST_FCM_TOKEN (run by fcm_phone_test.ps1)."""

import asyncio
import os
import sys

from jaga import alerts
from jaga.fcm import FcmPush

alert = alerts.build("alert", "phone-test", "money", "Caller: Pindahkan duit ke akaun selamat sekarang")
try:
    asyncio.run(FcmPush().send(os.environ["JAGA_TEST_FCM_TOKEN"], alert))
except Exception as e:
    sys.exit(f"Send failed ({type(e).__name__})")
