# 0007: Contracts v1: the server sends resolved phrase-library text, and four schemas are settled

Four contracts in `contracts/`, with examples in `contracts/fixtures/` (and ones that must fail in `contracts/fixtures/invalid/`):

- `stage-update` (server -> protected user's app). `source` (`rules` | `spark`) is required. At `risk=high` (Warning),
  `command` and `counterMove` are required non-empty strings; otherwise they are null or absent. Both carry **resolved
  phrase-library text**, not a phrase ID. `command` is one string, command language then English ("Letak telefon. Hang up.").
- `pause` (bank <-> Jaga Pause). One file: `#/$defs/request` is the request body (`pauseToken`, non-empty) and
  `#/$defs/response` the response; the schema root points at the response. `stage` uses the full stage enum.
- `family-alert` (server -> family co-pilot via FCM). Required `kind`: `alert` or `mayBeGenuine` (the follow-up when Muse
  Spark lowers a Warning after an alert went out). Never the transcript. FCM data values must be strings, so the server
  sends this object JSON-encoded in a single data field.
- `stage-timeline` (server -> family co-pilot's app). `callId`, `startedAt`, `endedAt` (null while live), `claimedAgency`,
  and `events`: one per stage or risk change, each with `at`, `stage`, `risk`, `source` and up to 3 masked evidence quotes.
  Never the transcript or audio. Kept 30 days.

**Why:** the phrase library and `official_contact` live on the server (spec modules list). Muse Spark still returns a
phrase ID (ADR 0006), and the server resolves it once, so there is one source of shown text, the app needs no copy of the
library to keep in sync per region pack and language, and a library fix ships without an app release. The cost is a
slightly larger message, which does not matter at a few messages per call. Making `command` and `counterMove` conditional
on risk in the schema enforces "no command on a Caution" at the seam instead of in each client.
