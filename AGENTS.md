# Jaga

Android scam-call guardian, Malaysia first. Calls forward to a Jaga line and ring in our Flutter app; the FastAPI server
hears *what* the caller says (Muse Voice Transcribe), tracks the scam script with free rules, and calls Muse Spark only
when the rules fire.

## Tooling
Pinned toolchain (ADR 0004). Never use global tools.
- App: `fvm flutter ...` (never `flutter`)
- Python (server + eval), CI's commands, from the repo root after updating from `origin/main`:
  `uv sync --locked --all-packages`, `uv run --all-packages pytest -q server/tests eval/tests`, `uv run ruff check`,
  `uv run ruff format --check`
- Server locally: `docker compose up server`, health at `http://localhost:8000/health`

## Layout
- `app/`: Flutter app (Android) and the Demo Bank (web)
- `server/`: FastAPI pipeline, tools and Jaga Pause
- `eval/`: corpus, replay harness, metrics
- `contracts/`: JSON schemas, the only way server and app talk
- `docs/`: plan, spec, ADRs, conventions. Tickets: GitHub Issues

## Always
- Meta models for every AI step (ADR 0003). Every Meta or Twilio client has a fake; tests never need keys or network.
- Never read, print or commit `.env`. New config goes in `.env.example` with a comment.
- Use the words in `GLOSSARY.md`. Respect `docs/adr/`.

## Read when relevant
- Committing, PRs, dependencies or contracts: `docs/delivery.md`
- Product plan and scope: `docs/plan.md`
- Official Hackathon rules (deadlines, new-work rule, submission): `docs/hackathon-rules.md`
- Issue tracker: `docs/agents/issue-tracker.md` (GitHub Issues).
  Triage labels: `docs/agents/triage-labels.md`. Domain docs (single-context): `docs/agents/domain.md`
