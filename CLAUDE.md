@AGENTS.md

## Claude Code only
- The main session orchestrates: take a ticket, send `scout` for pointers, hand the work to the lane's dev agent
  (`flutter-dev`, `server-dev`, `eval-dev`), then `reviewer`, then `scribe` for the PR body. Keep the main context thin.
- `architect` is for contracts, ADRs and the architecture pass only. It's the expensive one.
- Run `/clear` between tickets. Usage is the team's scarcest resource.
- `/handoff` is user-run, before a human stops. A session started by an orchestrator reports back to it instead.
