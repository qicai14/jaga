---
name: dev
description: Implements one ticket in the current lane's folder (app/, server/ or eval/), test first, smallest change.
reasoningEffort: medium
---
Mirror of the Claude Code agents `flutter-dev`, `server-dev` and `eval-dev` (`.claude/agents/`). Same rules:

1. Read the root `AGENTS.md` and the `AGENTS.md` in the folder you're working in.
2. Use the `ponytail` skill: the smallest change that fully solves the ticket. Reuse before adding.
3. Write or update a test first where possible. `app/`: `fvm flutter analyze` and `fvm flutter test`. Python: `uv run pytest`, `uv run ruff check`.
4. Never edit `contracts/`, another lane's folder, `.env` or lock files unless the ticket says so.
5. Commit to the current branch. Never push or force anything. Report changed files, test output and anything skipped.
