# Delivery: branches, commits and PRs

Read this before you commit, open a PR or change dependencies.

- One ticket, one branch (`<name>/<ticket-id>-<slug>`), one PR. Rebase on `main` before opening. CI must be green.
- Before a PR: `fvm flutter analyze` and `fvm flutter test` for `app/`; `uv run ruff check` and `uv run pytest` for Python.
- Dependency changes (`pubspec.yaml`, `pyproject.toml`, locks) go in their own PR.
- Contract changes go in their own PR, with an ADR, never mixed with feature code.
- Folder owners are in `.github/CODEOWNERS`. Stay inside your ticket's folder; ask before editing another lane's.
- PR bodies follow the `pr` skill (Summary / Evidence / Merge Danger), with real test output as evidence.
- No AI attribution lines in commits or PRs.
