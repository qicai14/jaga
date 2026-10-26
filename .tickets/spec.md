# Spec: Jaga MVP

Status: ready-for-agent

Source: `docs/plan.md`, `GLOSSARY.md`, ADRs 0001 to 0006, and the grilling session of 25 Oct 2026.

## Problem Statement

An elderly Malaysian parent answers a call from what their phone shows as a real police station number. The caller says
they're from the bank, then "transfers" them to a PDRM or Bank Negara officer who accuses them of money laundering, tells
them to tell no one, and walks them through moving their savings to a "safe account". Caller-ID apps trust the spoofed
number. Content-based scam detectors don't work in code-switched Malay, English, Mandarin and Tamil, and don't know the
Macau scam script. The family finds out after the money is gone, and very little of it ever comes back.

## Solution

The protected user's calls forward to a Jaga line and ring inside the Jaga Android app. While the call runs, Jaga listens
to what the caller says, tracks where they are in the Macau scam script, and steps in before money moves:

- At medium risk the protected user sees a quiet Caution. At high risk they see a Warning: one big command first
  ("Letak telefon. Hang up."), then a counter-move ("Say you'll call back, then phone the station's official number"),
  then the evidence.
- When the call reaches isolation or worse, the family co-pilots get a push with a short summary and up to two masked
  quotes, and a button to phone the protected user.
- If the protected user opens their bank app anyway, the bank asks Jaga Pause and holds the transfer.
- Jaga never hangs up or reports by itself. The protected user and family decide.

Evidence that it works comes from a Malaysian corpus and the TeleAntiFraud benchmark, run through the real pipeline.

## User Stories

### Protected user, during a call
1. As a protected user, I want calls to my normal number to ring in the Jaga app, so that Jaga can listen without me doing anything different.
2. As a protected user, I want to answer and talk as on any phone call, so that Jaga doesn't get in the way of genuine calls.
3. As a protected user, I want to see nothing extra during a genuine call, so that I'm not frightened by false alarms.
4. As a protected user, I want a quiet Caution banner when the call shows signs of a scam, so that I start to listen carefully.
5. As a protected user, I want a full-screen Warning with one big command when the call is very likely a scam, so that I know exactly what to do without reading.
6. As a protected user, I want the command in my own language followed by English, so that I understand it even when I'm panicking.
7. As a protected user, I want the same command words every time, so that I recognise them instantly.
8. As a protected user, I want a counter-move after the command, so that I have a safe thing to say if I don't hang up.
9. As a protected user, I want the counter-move to include the agency's real official number, so that I can check the caller's story myself.
10. As a protected user, I want to see a short piece of evidence of why Jaga is worried, so that I believe the Warning.
11. As a protected user, I want the Warning to appear within about 2 seconds of the scammer's line, so that it comes before I act on it.
12. As a protected user, I want the Warning to stay even if the caller tells me to ignore my phone app, so that the scammer can't talk Jaga out of it.
13. As a protected user, I want to dismiss a Caution or Warning from my screen, so that I can carry on a call I'm sure is genuine.
14. As a protected user, I want large text and high contrast on every screen, so that I can read it without my glasses.
15. As a protected user, I want Jaga to warn me if I start reading out a TAC, account number or IC, so that I stop before giving them away.
16. As a protected user, I want Jaga never to hang up or report for me, so that I stay in control of my own phone.

### Protected user, privacy
17. As a protected user, I want no audio of my calls stored anywhere, so that my private conversations stay private.
18. As a protected user, I want my transcript deleted when the call ends, so that nothing I said is kept.
19. As a protected user, I want my IC, account and OTP numbers masked before any AI model sees them, so that they can't leak.

### Setup
20. As a family co-pilot, I want to install and set up Jaga on my parent's phone myself, so that they never have to.
21. As a family co-pilot, I want setup to walk me through forwarding calls to the Jaga line, so that I get it right first time.
22. As a family co-pilot, I want to choose the region (Malaysia only in the MVP) and command language during setup (the region's default, Malay for Malaysia), so that my parent sees words they know and gets their country's official numbers.
23. As a family co-pilot, I want setup to give me a pause token to link my parent's bank, so that the bank can hold transfers during a scam.
24. As a family co-pilot, I want setup to show a link code, so that I and up to two other relatives can follow my parent.
25. As a family co-pilot, I want to enter the link code in my own Jaga app, so that I start getting alerts.
26. As a family co-pilot, I want to be told when the maximum of 3 family co-pilots is reached, so that I know why a fourth can't join.

### Family co-pilot, during and after a call
27. As a family co-pilot, I want a push when my parent's call reaches isolation or worse, so that I can step in before money moves.
28. As a family co-pilot, I want a second push if the call reaches money or credentials, so that I know it's getting worse.
29. As a family co-pilot, I want no more than two pushes per call, so that I'm not flooded while trying to help.
30. As a family co-pilot, I want the push to name the claimed agency and include a short summary, so that I understand the situation in seconds.
31. As a family co-pilot, I want up to two masked quotes in the push, so that I can judge for myself.
32. As a family co-pilot, I want a Call button in the alert that dials my parent, so that my call interrupts the scammer.
33. As a family co-pilot, I want a follow-up push if Jaga later thinks the call may be genuine, so that I don't panic for nothing.
34. As a family co-pilot, I want my alerts to keep coming even if my parent dismissed the Warning, so that a coached victim can't silence me.
35. As a family co-pilot, I want to see the stage timeline of a call afterwards, so that I can report it to our country's scam hotline (997 in Malaysia) or the bank.
36. As a family co-pilot, I want the timeline kept for 30 days, so that I have time to report it.
37. As a family co-pilot, I want to delete a timeline sooner, so that I control what's kept.
38. As a family co-pilot, I want to clear Jaga Pause early, so that my parent can make a genuine transfer after I've checked.

### Bank (Demo Bank)
39. As a bank, I want to ask Jaga Pause whether a customer is mid-scam using their pause token, so that I can hold a risky transfer.
40. As a bank, I want a recommended hold time with the answer, so that I know how long to hold.
41. As a bank, I want the claimed agency and stage in the answer, so that my staff can explain the hold.
42. As a bank, I want the scam status to last 30 minutes after the call ends, so that a victim who hangs up and opens the app straight away is still protected.
43. As a protected user using the Demo Bank, I want a clear "transfer held" screen, so that I understand why the money didn't move.
44. As a protected user, I want my own "this call is fine" tap not to clear Jaga Pause, so that a scammer can't coach me through it.

### Evidence (lane C) and judges
45. As an evaluator, I want to replay recorded calls through the real pipeline at real-time speed, so that the numbers match what ships.
46. As an evaluator, I want every corpus source to carry a usage note and a split by source, so that the evaluation is honest.
47. As an evaluator, I want to measure the share of scams caught before money, so that I can check the 90% target.
48. As an evaluator, I want false alarms per 10 hours of genuine calls, with Cautions reported separately, so that I can check the false-alarm target.
49. As an evaluator, I want p50 and p95 time from trigger line to Warning, so that I can check the 2 s target.
50. As an evaluator, I want an ablation of rules only, rules plus Spark, and Spark only, so that I can show what each part adds in accuracy, latency and cost.
51. As an evaluator, I want TeleAntiFraud near-domain Macro-F1, so that our results compare with published systems.
52. As an evaluator, I want red-team paraphrase, Manglish and injection variants as test data, so that I know how robust the rules are.
53. As an evaluator, I want Spark failures and timeouts counted, so that the fail-safe path is part of the numbers.
54. As a judge, I want an evidence table fixed before building, so that I can trust the results weren't tuned to look good.

### Developers
55. As a developer, I want the whole pipeline to run end to end with fakes and no keys, so that I can test without credits or network.
56. As a developer, I want server and app to talk only through the contracts, so that lanes can work in parallel.
57. As a developer, I want Muse Spark output validated against a schema, so that a bad response can't reach users.
58. As a developer, I want the transcript never placed in a system prompt, so that injection can't steer Spark.
59. As a developer, I want everything country-specific in a region pack, so that adding a country is a new pack and a corpus, not code changes.
60. As a judge, I want to see that Malaysia is the first region pack of many, so that I know the approach reaches beyond one country.

## Implementation Decisions

### Modules (server)
- **region pack**: all country-specific data, loaded per protected user: script packs, official contacts, scam hotline,
  languages, keywords, default command language. The MVP ships Malaysia only; no module may hard-code a country.
- **telephony**: accepts Twilio Media Streams for both legs (`caller`, `user`) of a call through the Jaga line, converts
  8 kHz mu-law to 16 kHz PCM, and owns the call's lifecycle (start, end, `callId`).
- **asr**: streams each leg to Muse Voice Transcribe with the region pack's `languageBias` and keyword list
  (Malaysia: Malay, English, Mandarin Chinese, Tamil; LHDN, PDRM, Bank Negara, akaun selamat, waran tangkap, TAC, 997). Emits transcript turns per leg.
- **stages**: the stage tracker. Deterministic rules from the region pack's **script pack** (Malaysia: Macau) (stages, hard triggers, keyword
  rules). Reads the caller leg for stages; reads the user leg only to detect the protected user disclosing a TAC,
  account number or IC, which moves the call to `credentials`.
- **spark**: escalation to Muse Spark with the masked snippet that fired. Returns stage, risk, evidence and a counter-move
  phrase ID, validated against a schema. Calls tools.
- **tools**: `official_contact(region, agency)` (static table per region pack), `check_mule(account|phone)` (mock labelled "production: PDRM
  partnership"), `alert_family(summary)`. `check_document` and `draft_report` are stretch.
- **phrase library**: the fixed, reviewed command and counter-move text per region pack, stage and language. Lane D owns the content.
- **alerts**: FCM pushes to family co-pilots.
- **pause**: the Jaga Pause API for banks.
- Every external client (Twilio, Muse Voice Transcribe, Muse Spark, FCM) has a fake; `JAGA_USE_FAKES=true` runs end to end.

### Stage and risk rules
- Stage severity: `none` < `pretext` < `authority` < `fear` < `isolation` < `handoff` < `money` = `credentials`. A call's
  stage is the most severe seen so far and never goes down.
- Risk is `low`, `medium` (Caution) or `high` (Warning) and can go down.
- Rules alone raise risk to medium at most (ADR 0005). A **hard trigger** raises a Warning at once with `source=rules`;
  Spark checks it afterwards.
- Spark is called on each new stage from `authority` up, at most 5 times per call, with a 1.5 s timeout.
- Spark may lower a rules-only Caution to low. It may lower a hard-trigger Warning to a Caution, never to low.
- Fail-safe: if Spark times out or fails, a call at `money` or `credentials` gets a Warning; below that it stays a Caution.
- The protected user sees only phrase-library text (ADR 0006). Spark writes free text only for the family summary
  (max 200 characters).

### Family alerts
- One push the first time a call reaches `isolation` or higher, one more on reaching `money` or `credentials`: at most 2
  per call, plus a follow-up "may be genuine" push if Spark lowers a Warning.
- Payload: protected user's name, stage, claimed agency, summary, up to 2 masked quotes. Never the transcript.
- One protected user per Jaga line; up to 3 family co-pilots, each following one protected user, linked with a link code.

### Jaga Pause
- The bank calls with the protected user's pause token.
- `inScam` is true while a call is live at `isolation` or higher, and for 30 minutes after that call ends.
- `recommendedHoldMinutes`: 30 at `money`/`credentials`, 15 at `isolation`/`handoff`, 0 otherwise.
- Only a family co-pilot can clear it early. The protected user's dismissal never clears it.

### Contracts (finalise on 26 Oct by ADR, in their own PR)
- `stage-update`: `command` and `counterMove` are non-null only when `risk=high`. Add the counter-move phrase ID if the
  app renders text locally, or keep resolved text from the server; decide in the contracts PR.
- `pause`: add the request shape carrying the pause token.
- `family-alert`: add a kind for the follow-up "may be genuine" push.
- New: the stage timeline shape (stages, times, risk changes, `source`, masked evidence) for the family app.

### App (Android, plus Flutter web for the Demo Bank)
- Features: call (incoming via `twilio_voice`), warning (Caution banner, Warning screen), family (alerts, Call button,
  timeline, clear Jaga Pause), onboarding (forwarding, language, pause token, link code), demo_bank (transfer, held screen).
- Region pack and command language set at onboarding (the region's default; Malay for Malaysia), always followed by English. Not detected from the call.
- Dismissing a Caution or Warning only hides it on the protected user's screen.

### Privacy
- Standard-mode Meta models only, zero data retention requested, no audio stored, IC/account/OTP masked before Spark,
  transcript deleted at call end, stage timeline kept 30 days (family can delete sooner), shown only in the family app.

## Testing Decisions

- A good test checks behaviour at an outside edge and survives a rewrite of the internals. No tests of private helpers.
- **Seam 1, the server's outside edge:** a scripted call goes into the Twilio Media Streams WebSocket under
  `JAGA_USE_FAKES=true`. The fake transcriber turns each audio chunk into a scripted line, so a test reads like a call
  script. Tests assert only on what comes out: `stage-update` messages, `family-alert` pushes recorded by the fake push
  client, and `pause` API answers for a pause token. This seam covers stage monotonicity, the rules-only Caution cap, hard
  triggers, Spark lowering risk, the Spark timeout fail-safe, the 2-push limit, the pause window and hold minutes, masking,
  and injection lines having no effect.
- The **replay harness** uses the same seam with real audio and real APIs, so the evaluation exercises shipped code.
- **Seam 2, app screens:** Flutter widget tests feed contract-shaped messages into each screen through a fake server
  connection and assert on what the user sees (nothing at low risk, command first in a Warning, dismiss is local only,
  the family Call button, the held-transfer screen).
- **Contract check:** every JSON fixture used by either seam is validated against `contracts/*.schema.json`.
- No unit seams inside the pipeline unless a ticket needs one, such as the stage tracker's rule table.
- Prior art: the `/health` test (FastAPI `TestClient`) and the starter Flutter widget test.

## Out of Scope

- iOS (ADR 0001).
- Real carrier forwarding from a Malaysian SIM (needs a +60 number); the demo uses a US Twilio number called directly.
- Deepfake-voice detection.
- Cantonese and Hokkien (not supported by Muse Voice Transcribe).
- Job and trafficking-recruitment scams: a later script pack.
- Family barge-in to the live call.
- Jaga hanging up or reporting by itself.
- Stretch, only after the MVP, in order: golden-hour pack, document check, family code-word challenge, monthly scam fire
  drill, script intelligence, cooling-off flow, Nenek decoy line, a Singapore region pack (demo only, no evaluation
  numbers; verify its official contacts and hotline first).

## Further Notes

- Day-1 tests on 26 Oct decide the riskiest assumptions: `<Start><Stream track="both_tracks">` with `<Dial><Client>`,
  `twilio_voice` incoming calls on Android, connect time, and transcription quality on 8 kHz audio. Fallback for
  telephony: a browser dialer calls the Jaga number.
- Re-read the Official Rules on 26 Oct before committing; the rules may limit pre-built code.
- The hard-trigger list and the phrase library's wording are open content work for lanes A and D.
- Check PDPA 2010 and recording consent before making any legal claims.
- Targets are fixed in `docs/plan.md` §5; report misses honestly and never tune on the held-out set.
