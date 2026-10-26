# Issue tracker: GitHub Issues

Tickets live in GitHub Issues on `qicai14/jaga`; use the `gh` CLI. The spec is `docs/spec.md`. Issues #1 to #26 are the
original tickets 001 to 026, so a ticket number is its issue number.

## Conventions

- Labels on each issue:
  - one lane: `lane-a`, `lane-b`, `lane-c` or `lane-d` (see `docs/plan.md` §8)
  - one triage role (see `triage-labels.md`)
- `Blocked by: #N, #N` as the first body line (omit when nothing blocks it)
- Each issue has acceptance criteria as a checklist and is sized to one session
- Conversation goes in issue comments; the PR that closes it says `Closes #N`

## When a skill says "publish to the issue tracker"

`gh issue create --title "..." --body-file <file> --label lane-x --label needs-triage`

## When a skill says "fetch the relevant ticket"

`gh issue view <N> --comments`. The user will normally pass the issue number.

## Wayfinding operations

Used by `/wayfinder`. The **map** is an issue with one **child** issue per question.

- **Map**: an issue labelled `map` (the Notes / Decisions-so-far / Fog body).
- **Child ticket**: an issue whose first body line is `Part of #<map>`, with the question in the body and a `Type:` line
  (`research`/`prototype`/`grilling`/`task`).
- **Blocking**: a `Blocked by: #N, #N` line. A child is unblocked when every issue it lists is closed.
- **Frontier**: open, unblocked, unassigned children of the map; lowest number wins.
- **Claim**: `gh issue edit <N> --add-assignee @me` before any work.
- **Resolve**: comment the answer under an `## Answer` heading, close the issue, then add a context pointer (gist + link)
  to the map's Decisions-so-far.
