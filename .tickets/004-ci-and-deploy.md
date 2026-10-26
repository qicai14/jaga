# 004: CI and Fly.io deploy

Lane: D
Status: ready-for-agent
Blocked by: None (can start immediately)

**What to build:** Every PR is checked automatically and `main` is live on Fly.io.

- [ ] Every PR runs ruff, pytest, `fvm flutter analyze` and `fvm flutter test` with the pinned toolchain
- [ ] The contract fixture check runs in CI once 001 lands
- [ ] Merging to `main` deploys the server to Fly.io and `/health` returns ok
- [ ] The Fly app name is confirmed free
