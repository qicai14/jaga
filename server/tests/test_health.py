from fastapi.testclient import TestClient

from jaga.main import app


def test_health_ok():
    assert TestClient(app).get("/health").json() == {"status": "ok"}
