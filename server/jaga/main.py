from fastapi import FastAPI

from jaga import pause, telephony

app = FastAPI(title="Jaga")
app.include_router(telephony.router)
app.include_router(pause.router)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
