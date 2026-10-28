from fastapi import FastAPI

from jaga import pause, telephony, timelines

app = FastAPI(title="Jaga", redirect_slashes=False)
app.include_router(telephony.router)
app.include_router(pause.router)
app.include_router(timelines.router)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
