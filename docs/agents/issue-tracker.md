# Issue tracker: Local Markdown (until 26 Oct)

Before the GitHub repo exists, the spec and tickets live as markdown files in `.tickets/`. On 26 Oct the lead moves them
to GitHub Issues and this file is rewritten for GitHub (see `.tickets/README.md`).

## Conventions

- The spec is `.tickets/spec.md`
- One file per ticket at `.tickets/NNN-<slug>.md`, numbered from `001`, never a single combined tickets file
- Near the top of each ticket:
  - `Lane: A|B|C|D` (one lane per ticket, see `docs/plan.md`)
  - `Status:` the triage role string (see `triage-labels.md`)
  - `Blocked by: NNN, NNN` (omit when nothing blocks it)
- Each ticket has acceptance criteria and is sized to one session
- Comments and conversation history append to the bottom of the file under a `## Comments` heading

## When a skill says "publish to the issue tracker"

Create a new file under `.tickets/`, taking the next free number.

## When a skill says "fetch the relevant ticket"

Read the file at the referenced path. The user will normally pass the path or the ticket number directly.

## Wayfinding operations

Used by `/wayfinder`. The **map** is a file with one **child** file per ticket.

- **Map**: `.tickets/<effort>/map.md` (the Notes / Decisions-so-far / Fog body).
- **Child ticket**: `.tickets/<effort>/NNN-<slug>.md`, numbered from `001`, with the question in the body. A `Type:` line records the ticket type (`research`/`prototype`/`grilling`/`task`); a `Status:` line records `claimed`/`resolved`.
- **Blocking**: a `Blocked by: NNN, NNN` line near the top. A ticket is unblocked when every file it lists is `resolved`.
- **Frontier**: scan `.tickets/<effort>/` for files that are open, unblocked, and unclaimed; first by number wins.
- **Claim**: set `Status: claimed` and save before any work.
- **Resolve**: append the answer under an `## Answer` heading, set `Status: resolved`, then append a context pointer (gist + link) to the map's Decisions-so-far in `map.md`.
