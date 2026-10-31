from datetime import UTC, datetime

import pytest

from jaga import telephony

PAUSE = "test-pause-token"
START = datetime(2026, 1, 1, 12, 0, tzinfo=UTC)


@pytest.fixture
def clock(monkeypatch):
    """The one clock the server reads; tests move it."""
    now = [START]
    monkeypatch.setattr(telephony, "now", lambda: now[0])
    monkeypatch.setattr(telephony, "calls", {})
    monkeypatch.setenv("JAGA_PAUSE_TOKEN", PAUSE)
    return now
