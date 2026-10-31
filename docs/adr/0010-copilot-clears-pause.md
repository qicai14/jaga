# 0010: A family co-pilot clears Jaga Pause over two token-guarded routes; a later stage holds it again

**Decision:** the family co-pilot's app reads and clears Jaga Pause over two new routes. There is no new schema: both
answer `#/$defs/response` of the `pause` contract, and `inScam` is the state the app parses. This widens ADR 0007's "bank
<-> Jaga Pause": the same response now also goes to the co-pilot.

**The routes.** No request body and no query string on either.

- `GET /copilot/pause`: the current state. Backs `CopilotPauseService.isActive()` (lane B, PR #44).
- `POST /copilot/pause/clear`: clears, then answers the state after the clear. Backs `clear()`.
- 404: `Authorization: Bearer <JAGA_COPILOT_TOKEN>` is missing or wrong, or the variable is unset. The same constant-time
  check and bare 404 as ADR 0008, which said #59 would reuse it.

**Who can clear.** That token is how the caller proves they are the linked family co-pilot. The protected user's app holds
`JAGA_APP_TOKEN` (ADR 0009) and the bank `JAGA_PAUSE_TOKEN`; neither opens these routes. There is no dismissal route for the
protected user, so their dismissal cannot clear. `JAGA_COPILOT_TOKEN`, `JAGA_APP_TOKEN` and `JAGA_PAUSE_TOKEN`
must be three different values, because the protected user hands the pause token to their bank. The routes sit under `/copilot`, so `PauseCORS`, which matches the exact
path `/pause`, gives them no browser access, and they stay clearly apart from the bank's check.

**What a clear does.**

- It covers the calls holding the pause at that moment: live at `isolation` or higher, or ended within the last 30 minutes
  at that level. It names no call or stage, so it also covers a stage the co-pilot's screen had not shown yet. A live call
  below `isolation` is not holding the pause, so it is not covered and pauses as usual if it gets there.
- A covered call stops counting towards the answer, so `stage` is the most severe among the current calls not covered, and
  `none` if there are none (`fixtures/pause/response-cleared.json`). The call's own stage does not change: tracking, family
  alerts and the stage timeline carry on. A clear is not a timeline event and sends no push.
- A clear always answers `inScam: false`. It is idempotent, so retrying after a lost response is safe. Clearing with nothing
  active is 200 with `inScam: false`.
- If a covered call's stage later differs from the one it was cleared at, the pause holds again with the usual hold, until
  the next clear. A stage never goes down, so that means a higher stage or the move from `money` to `credentials`, which tie
  in rank (GLOSSARY) but mean the victim has now given a code away. A new call pauses as usual.
- After a clear, `POST /pause` answers the bank with the same state as `GET /copilot/pause`.

**Inherited limit.** One protected user, one env token, in memory: the same #12/#19 shortcuts as `pause.py` and
`timelines.py`, and a restart loses clears along with the calls. Whoever holds the token can clear, so the keep-out above
holds only while `JAGA_COPILOT_TOKEN` stays off the protected user's phone. The role is chosen at runtime in one APK, so the
token must not be compiled into the build installed there, and it must stay out of `build-apk.yml`'s public artifact.
Upgrade with per-co-pilot auth (#12/#19).

**Lanes that must update:**

- Lane D (#59): the two routes with the `copilot` check from `timelines.py`; the per-call clear, honoured by `POST /pause`;
  tests at the seam that validate answers against the contract; name the new routes in `.env.example`'s `JAGA_COPILOT_TOKEN`
  comment.
- Lane B (PR #44): an HTTP `CopilotPauseService` over the two routes, parsing `response-cleared.json`; give the token only to
  a co-pilot's install, for example a separate build.

**Why:** the pause token can't prove anything about the caller, because the protected user gives it away to their bank, and
scammers coach victims to act on their own phone (plan, safety rules). The co-pilot token already separates the family from
the protected user's app, so reusing it adds no new pattern. One response shape means one thing to parse and no way for the
bank and the co-pilot to disagree. Holding again costs a genuine call a second clear, but the co-pilot only vouched for what
they had seen so far, and a missed scam is worse than a false alarm.
