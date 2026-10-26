# Same image locally (docker compose) and on Fly.io. Build context is the repo root (uv workspace + lock).
FROM ghcr.io/astral-sh/uv:0.12.24 AS uv
FROM python:3.13-slim

COPY --from=uv /uv /usr/local/bin/uv
ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy UV_PYTHON_DOWNLOADS=never
WORKDIR /repo

COPY pyproject.toml uv.lock .python-version ./
COPY server/pyproject.toml server/pyproject.toml
COPY eval/pyproject.toml eval/pyproject.toml
COPY server/jaga server/jaga
RUN mkdir -p eval/jaga_eval && touch eval/jaga_eval/__init__.py \
 && uv sync --locked --no-dev --package jaga-server

ENV PATH="/repo/.venv/bin:$PATH"
EXPOSE 8000
CMD ["uvicorn", "jaga.main:app", "--host", "0.0.0.0", "--port", "8000"]
