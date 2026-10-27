from fastapi import FastAPI

from jaga import spike, telephony

app = FastAPI(title="Jaga")
app.include_router(telephony.router)
app.include_router(spike.router)  # shortcut: day-1 telephony spike, delete when the telephony module lands


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
