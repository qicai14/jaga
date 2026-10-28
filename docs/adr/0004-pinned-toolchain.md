# 0004: One pinned toolchain for everyone

**Decision:**
- Flutter 3.47.7 / Dart 3.13.5 via FVM (`app/.fvmrc`, `pubspec.yaml` environment). `pubspec.lock` is committed.
  CI has no FVM: `subosito/flutter-action` reads the same version from `pubspec.yaml` and runs plain `flutter`.
- Python 3.13 via uv 0.12.24 (`.python-version`, `[tool.uv] required-version`). One `uv.lock` for server and eval.
- The server runs in the same Docker image locally (`docker compose`) and on Fly.io.
- `.gitattributes` forces LF line endings. Agent skills are pinned in `skills-lock.json`.
**Why:** four people on different machines and different AI tools must get identical behaviour, and lock files stop
"works on my machine" bugs. A full dev container was rejected: the Android emulator doesn't run well inside Docker on Windows.
**Upgrading:** one person bumps a version in a dependency-only PR. Everyone runs `fvm install` / `uv sync` after merging.
