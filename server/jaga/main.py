from fastapi import FastAPI

from jaga import telephony

app = FastAPI(title="Jaga")
app.include_router(telephony.router)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
