# Jaga: the plan

> One plan, merged from the concept (v2) and north-star drafts and cleaned up on 24 Oct 2026. This is the input for
> `/to-spec`, which turns it into `docs/spec.md`. Decisions are in `docs/adr/`, vocabulary in `GLOSSARY.md`.

## 1. Outcome
**No money leaves a protected user's account because of a scam call.** Detection is one step. Interrupting the scammer,
helping the user verify, pulling in family and slowing the transfer are the rest.

## 2. Problem
- Malaysians lost **RM2.97B** to online scams in 2025. Telecom scams took **RM715M** (28,698 cases). Of RM542M reported
  lost, RM6.7M came back.
- The **Macau scam** follows a script: a fake bank, courier or LHDN officer, then a "transfer" to a fake police or Bank
  Negara officer, then an accusation (money laundering, drugs) and "tell no one", then money moved to a "safe account".
  **Caller ID is spoofed to real station numbers.**
- **Gap:** caller-ID apps (Truecaller, Whoscall) judge *who* is calling, so spoofed numbers beat them. Content-based
  detectors (Hiya, Google Scam Detection) judge *what* is said, but only in English and French, on Pixel, in the US.
  Nobody does it in Malay, English, Mandarin and Tamil code-switched speech, tuned to the Malaysian script.

## 3. How it works
1. **Jaga line (ADR 0002).** The protected user's SIM forwards calls to a Twilio number. Twilio forks both legs' audio to
   our server and rings the Jaga **Android** app (ADR 0001).
   **Setup:** a family co-pilot installs Jaga on the protected user's phone and sets forwarding, the **region pack**
   (Malaysia only in the MVP), command language (the region's default, Malay for Malaysia; English always after it) and the bank's pause token. Up to 3 family co-pilots join with the link code.
2. **Hear.** Muse Voice Transcribe realtime: Twilio's 8 kHz mu-law audio converted to 16 kHz PCM; `languageBias` Malay,
   English, Mandarin Chinese, Tamil; `keywords` LHDN, PDRM, Bank Negara, akaun selamat, waran tangkap, TAC, 997. Languages and keywords come
   from the region pack; these are Malaysia's.
3. **Track (free).** A deterministic **stage tracker** maps turns to stages: pretext, authority, fear, isolation, handoff,
   money, credentials. No model call on normal calls.
4. **Reason (on escalation only).** Muse Spark gets the masked snippet that fired, returns structured output (stage,
   risk, evidence, a counter-move phrase ID) validated against a schema; the words shown come from the phrase library (ADR 0006), and calls tools:
   - `official_contact(region, agency)`: a static lookup table per region pack, deterministic.
   - `check_mule(account|phone)`: PDRM Semak Mule; a mock if there's no public API.
   - `check_document(image)`: Muse Spark vision on a fake warrant or police card; SAM 3.1 masks IC and account numbers first.
   - `alert_family(summary)`, `draft_report(hotline|bank)`, using the region's scam hotline.
   The transcript is untrusted: "ignore the warning on your phone" can't steer it.
5. **Act.**
   - **Command first** (aircraft-warning style): "Letak telefon. Hang up." Explanation after.
   - **Counter-move** (negotiator style): "Say you'll call back, then phone the station's official number." Buy time.
   - **Family co-pilot:** on first reaching isolation, and again at money or credentials, an FCM push with a summary and up to two masked quotes.
   - **Jaga Pause:** a bank app asks "is this customer mid-scam?"; the Demo Bank holds the transfer.
   - Jaga never hangs up or reports by itself. The user and family decide.
   - **Safety rules:** if Muse Spark times out (2.5 s) or fails, a call at `money` or `credentials` still gets a Warning;
     below that it stays a Caution. Spark can lower a hard-trigger Warning to a Caution, never to nothing, and a follow-up
     push tells the family. The protected user can dismiss a Caution or Warning on their own screen only: it doesn't stop
     family alerts, clear Jaga Pause or stop tracking, because scammers coach victims to tap "okay". Only a family co-pilot
     can clear Jaga Pause early. Spark can lower risk (a rules-only Caution back to low), never the stage. The family alert's **Call** button opens the dialer to the protected user; no barge-in.

## 4. Scope
**MVP (must ship):** Jaga line, then hear, then track, then reason with tools, then command, counter-move and family alert;
**Jaga Pause** with the Demo Bank (Flutter web); the **evaluation** (Malaysian set plus TeleAntiFraud).
Everything country-specific lives in a **region pack**; the MVP ships **Malaysia** only. Adding a country means a new
region pack plus its own corpus, not code changes.
**Stretch, in order:** golden-hour pack, document check, family code-word challenge, monthly scam fire drill, script
intelligence (anonymised stage patterns), cooling-off flow, Nenek decoy line, a **Singapore** region pack (demo only, no evaluation numbers; verify its
official contacts and hotline before use).
**Out:** iOS, real carrier forwarding from a Malaysian SIM (needs a +60 number), deepfake-voice detection, Cantonese and
Hokkien (not supported by Muse Voice Transcribe), job and trafficking-recruitment scams (mostly over messaging and
aimed at younger people; a later **script pack**, the stage tracker ships with the Macau pack only).

## 5. Evidence: judged by data, not by us
- **Malaysian corpus:** real scam recordings (PDRM and CCID clips, news audio, victim and scambaiter uploads), court
  judgments quoting scripts, genuine bank, courier and LHDN calls. Every source gets a usage note. Audio stays local.
- **Labels:** stage per line; a second person labels the held-out set; agreement measured with Cohen's kappa. Split by source.
- **Public benchmark:** TeleAntiFraud-28k binary test (Apache 2.0, gated on Hugging Face; 400 calls, fraud vs normal).
  The paper (arXiv:2503.24115, Table 4) reports weighted F1 on fraud detection, e.g. Qwen2.5-72B ASR+LLM 51.44,
  DeepSeek-R1 79.25, AntiFraud-Qwen2-Audio 84.78. We report Macro-F1 and weighted F1. Text path first, audio on a
  subset (about $5 of transcription).
- **Replay harness:** recorded audio through the real pipeline at real-time speed.
- **Ablation:** rules only vs rules plus Spark vs Spark only (accuracy, latency, cost).
- **Red team:** paraphrase, Manglish and injection variants, used as test data only.
- **Head-to-head:** the same spoofed "PDRM" call to a phone running Truecaller vs Jaga.
- **Human trial:** a consented role-play with elderly relatives, with and without Jaga.

**Caught**, **false alarm** and **genuine call** are defined in `GLOSSARY.md`.

| Target (fixed before building) | MVP | Stretch |
|---|---|---|
| Scams caught before the `money` stage | at least 90% | at least 95% |
| False alarms on genuine calls | at most 1 per 10 hours | 0 in the trial set |
| Warning after the trigger line (p95) | within 2 s | within 1.5 s |
| TeleAntiFraud-28k binary test Macro-F1 | at least 0.75 | at least 0.80 |
| Completed transfers in protected role-play | 0 | 0 |

## 6. Privacy (ADR 0003)
Standard mode only, never contributor models; request zero data retention; no stored audio; IC, account and OTP numbers
masked before Muse Spark; Spark sees only the escalated snippet; family get a summary; transcripts deleted when the call ends;
only the stage timeline is kept (30 days, or less if a family co-pilot deletes it), and only the family app shows it. Check PDPA 2010 and recording consent before making legal claims.

## 7. Architecture
```
caller --> Twilio number --(both legs, Media Streams)--> server: telephony -> asr -> stages --(escalate)--> spark -> tools
                    \--(Voice SDK, FCM)--> Jaga app (protected user)  <--stage-update--/        \--> alerts --> family app
Demo Bank (Flutter web) --> server: pause API
```
Server: FastAPI on Fly.io (always-on WebSocket). Push, auth, small data: Firebase. Contracts: `contracts/*.schema.json`.

## 8. Team lanes
| Lane | Owner | Folders | Owns |
|---|---|---|---|
| A. Core pipeline and lead | Qi Cai | `server/` (core), `contracts/`, `.claude/` | telephony, asr, stages, spark escalation, stage-update stream, orchestration |
| B. App | Preston | `app/` | incoming call (`twilio_voice`), warning UI, family role and FCM, onboarding, localisation |
| C. Evidence | Foon or Joshua | `eval/` | corpus, labels, replay harness, TeleAntiFraud, metrics report |
| D. Product edges and ship | Joshua or Foon | `server/jaga/{tools,pause}`, `app/lib/features/demo_bank`, `.github/workflows` | phrase library, official contacts, mule mock, Jaga Pause and Demo Bank, golden-hour pack, CI and deploy, demo video |

## 9. Timeline (build window 26 Oct to 4 Nov, 9 PM ET)
| Date | Milestone |
|---|---|
| 26 Oct (kickoff) | Rules read (`docs/hackathon-rules.md`). Push the scaffold, tag `pre-hackathon`, protect `main`, tickets to Issues. No feature code before the building period (27 Oct ET) |
| 27 Oct | Finalise contracts. Day-1 tests: Twilio audio fork, connect time, 8 kHz transcription quality |
| 27 to 29 Oct | First end-to-end call with a warning on fakes, then on real APIs |
| 30 Oct to 1 Nov | Tools, family alert, Jaga Pause. Evaluation numbers. Architecture pass (31 Oct) |
| 2 to 3 Nov | Stretch items, polish, feature freeze on the 3rd |
| 4 Nov | Demo video, submission |

## 10. Demo (3 min)
1. A spoofed "PDRM" number calls grandma. A caller-ID app trusts it.
2. Code-switched Malay and English: pretext, handoff, "tell no one".
3. At "safe account": **"Letak telefon"** on her screen; her son's phone buzzes with quotes; Jaga coaches "say you'll call back".
4. The scammer says "ignore your phone app". No effect.
5. Shaken, she opens the Demo Bank. **Jaga Pause holds the transfer.**
6. A genuine bank card-check call: no alarm.
7. The evidence table, judged by held-out recordings and the public benchmark.
Closing line: "Caller-ID asks who's calling. Jaga asks what they want, and stops the money."

## 11. Risks
| Risk | Plan |
|---|---|
| Telephony setup and connect delay | Day-1 test. Fallback: a browser dialer calls the Jaga number |
| Transcription quality on 8 kHz audio | Day-1 test. Keyword biasing; report the error rate |
| False alarms on genuine calls | Genuine calls in every evaluation set; rules plus Spark ablation |
| No public Semak Mule API | Mock with an explicit "production: PDRM partnership" label |
| Corpus licensing and privacy | The rules disqualify data we lack rights to: usage note per source, audio never committed, unlicensed clips never in the demo video |
| Rules on pre-built code | Checked 26 Oct: allowed if clearly identified. Scaffold is setup only, tagged `pre-hackathon`, listed in the README; the demo shows only work after the tag |
| Scope creep | MVP first; stretch only from the ordered list |
