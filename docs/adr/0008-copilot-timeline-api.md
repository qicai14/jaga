# 0008: Family co-pilots read stage timelines over a token-guarded HTTP API; a miss is a bare 404

The server serves stage timelines to the family co-pilot's app (the `TimelineService` in lane B, PR #44) over three
endpoints. A new contract, `stage-timeline-list`, is a JSON array of `stage-timeline` items (by `$ref`), newest first by
`startedAt`. JSON Schema can't enforce the order, so the server sorts and the schema says so.

- `GET /timelines` returns `stage-timeline-list` (empty array when nothing is kept).
- `GET /timelines/{callId}` returns one `stage-timeline`.
- `DELETE /timelines/{callId}` returns 204. This is "family can delete sooner".
- Every request carries `Authorization: Bearer <JAGA_COPILOT_TOKEN>`, compared in constant time (`hmac.compare_digest`).
  A missing or wrong token, and an unknown `callId`, all get the same bare 404 with no body, so the protected user's app
  (which has no token) gets nothing, and nobody can probe which calls exist.
- The store is in memory and drops a timeline 30 days after the call. **Shortcut:** one token, no per-user scoping, and a
  restart loses everything; upgrade to a real store and per-co-pilot auth after #12 and #19.
- A stage timeline never holds the transcript or audio, and evidence quotes are masked before they are kept.
- #59 (a family co-pilot clears Jaga Pause early) reuses the same co-pilot check.

Contract tests resolve cross-file `$ref` through a `referencing` registry of every schema keyed by its `$id`, so
`stage-timeline-list` points at `stage-timeline` instead of copying it.

**Why:** the app already needs a single timeline (`stage-timeline`, ADR 0007); a list that refers to it keeps one shape
for both endpoints and one place to change it. A bearer token is the least that keeps the protected user's app out (spec:
"shown only in the family app") without waiting on link codes and Firebase auth. A bare 404 instead of 401/403 leaks
neither that the endpoint is guarded nor that a call happened. The cost of the in-memory store is that timelines don't
survive a deploy, which is fine for the demo and is why the 30-day rule lives in the server, not the schema.
