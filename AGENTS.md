# Jaga

Scam-call guardian for Malaysian families. Calls forward to a Jaga line and ring inside our Android app. The server listens
to *what* the caller says (Muse Voice Transcribe), tracks the scam script's stages with free rules, and calls Muse Spark
only when the rules fire. Plan: `docs/plan.md`. Words we use: `GLOSSARY.md`. Decisions: `docs/adr/`.

## Commands
Toolchain is pinned. Use the pinned tools, never global ones.
- App: `cd app && fvm flutter pub get`, `fvm flutter analyze`, `fvm flutter test`
- Python (server + eval): `uv sync --locked`, `uv run ruff check`, `uv run ruff format`, `uv run pytest`
- Server locally: `docker compose up server` (same image as deploy), health at `http://localhost:8000/health`

## Rules
- Meta models for every AI step (hear, see, reason). Any tool is fine for plumbing. ADR 0003.
- Server and app talk only through `contracts/*.schema.json`. Change a contract by ADR, in its own PR, never mixed with feature code.
- Every Meta or Twilio client has a fake in `server/jaga/fakes/`. Tests never need keys, credits or network.
- Never read, print or commit `.env`. New config goes in `.env.example` with a comment.
- Dependency changes (`pubspec.yaml`, `pyproject.toml`, locks) go in their own PR.
- One ticket, one branch (`<name>/<ticket-id>-<slug>`), one PR. Rebase on `main` before opening. CI must be green.
- Folder owners are in `.github/CODEOWNERS`. Stay inside your ticket's folder; ask before editing another lane's.

## Where to look
`app/AGENTS.md`, `server/AGENTS.md`, `eval/AGENTS.md` hold each area's rules. Tickets: GitHub Issues (`.tickets/` before kickoff).

## Agent skills

### Issue tracker

Local markdown in `.tickets/` until 26 Oct, then GitHub Issues. See `docs/agents/issue-tracker.md`.

### Triage labels

The five default labels (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `GLOSSARY.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.
