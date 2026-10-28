import os

from fastapi import FastAPI
from starlette.middleware.cors import CORSMiddleware

from jaga import pause, telephony, timelines


class PauseCORS:
    """Lets the web Demo Bank (DEMO_BANK_ORIGINS) call POST /pause from a browser; nothing else gets CORS."""

    def __init__(self, app):
        self.app = app

    async def __call__(self, scope, receive, send):
        raw = os.environ.get("DEMO_BANK_ORIGINS", "").split(",")
        origins = [o.strip().rstrip("/") for o in raw if o.strip().rstrip("/")]
        if (
            origins
            and scope["type"] == "http"
            and scope["path"] == "/pause"
            and scope["method"] in ("POST", "OPTIONS")
        ):
            # shortcut: built per request so the env is read live; upgrade if /pause gets hot
            cors = CORSMiddleware(
                self.app, allow_origins=origins, allow_methods=["POST"], allow_headers=["content-type"]
            )
            return await cors(scope, receive, send)
        await self.app(scope, receive, send)


app = FastAPI(title="Jaga", redirect_slashes=False)
app.add_middleware(PauseCORS)
app.include_router(telephony.router)
app.include_router(pause.router)
app.include_router(timelines.router)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
