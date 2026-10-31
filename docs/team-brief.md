# Jaga: team brief

**Meta Global AI Developer Hackathon 2026 · Indie track · Build window: 26 Oct to 4 Nov (submissions due 4 Nov, 9 PM ET = 5 Nov, 9 AM MYT)**
Team: Qi Cai (lead), Preston, Foon, Joshua

---

## TL;DR
Jaga is an Android app that protects people, especially our parents and grandparents, from **phone scams**. Calls ring
inside Jaga, so Jaga can listen to **what the caller is saying** in Malay, English or Mandarin. When the call follows
the Macau-scam script, Jaga tells the user **"Letak telefon. Hang up."**, coaches them what to say, alerts a family member,
and can make the bank **hold the transfer**. Our goal: **no money leaves the account.**

---

## 1. The problem
- Malaysians lost **RM2.97 billion** to online scams in 2025. Phone scams alone took **RM715 million**. Very little ever
  comes back (RM6.7M of RM542M reported).
- The **Macau scam** always follows the same script:
  1. "This is the bank / Pos Laju / LHDN, there's a problem with your account or parcel."
  2. "I'm transferring you to the police."
  3. "Your IC is linked to money laundering. **Don't tell anyone.**"
  4. "Move your money to this **safe account** so we can investigate."
- Scammers **spoof real police station numbers**, so caller-ID apps (Truecaller, Whoscall) can't help: they judge *who* is
  calling, and the number looks legitimate.
- Apps that analyse *what* is said exist (Hiya, Google Scam Detection), but only in English or French, on Pixel phones,
  in the US. **Nobody does this for Malaysian languages and Malaysian scam scripts.**

## 2. What Jaga does
> Caller-ID asks *who's* calling. Jaga asks *what they want*, and stops the money.

1. **Calls ring inside Jaga.** The user's SIM forwards calls to a "Jaga line" (a Twilio number), which rings our app.
   Android and iOS don't let apps hear normal phone calls, so this is how Hiya does it too.
2. **Jaga listens.** Meta's **Muse Voice Transcribe** turns both sides of the call into text live, even with mixed
   Malay, English and Mandarin.
3. **Jaga tracks the script (free, no AI).** Simple rules spot which stage the caller has reached: pretext, authority,
   fear, isolation ("tell no one"), handoff, money or credentials.
4. **Jaga thinks only when needed.** When the rules fire, Meta's **Muse Spark** checks the situation and can use tools:
   look up the agency's real hotline, check whether the "safe account" is a known mule account, or read a fake "warrant"
   sent on WhatsApp (with **SAM 3.1** blurring the IC number first).
5. **Jaga acts.**
   - One big command first: **"Letak telefon. Hang up."**
   - A counter-move: *"Say you'll call back, then phone the station's official number."*
   - A **family alert** to a son or daughter with a short summary, so the victim isn't alone anymore.
   - **Jaga Pause:** if she opens her bank app, the bank asks Jaga "is she mid-scam?" and holds the transfer.

**Privacy:** no audio stored; IC, account and OTP numbers masked before the AI sees anything; family get a summary, not
the transcript; Meta's Standard mode (data not used for training) with zero data retention.

## 3. What we will build
- **Must ship (MVP):**
  - The Jaga line and live listening.
  - The script tracker, with Muse Spark and its tools.
  - The warning screen, counter-move and family alert.
  - Jaga Pause with a mock **Demo Bank**.
  - **Proof that it works** (section 4).
- **Stretch, in order, only if MVP is done:**
  1. Golden-hour report for the scam hotline (997 in Malaysia) or the bank
  2. Fake-document check
  3. Family code word (beats cloned voices)
  4. Monthly scam fire drill
  5. Anonymised scam-script intelligence
  6. Cooling-off flow
  7. "Nenek" decoy line that wastes scammers' time
  8. A Singapore region pack (demo only)
- **Built for more than Malaysia:** everything country-specific (scam scripts, hotlines, official numbers, languages,
  keywords) lives in a **region pack**. We ship Malaysia only; a new country is a new pack plus its own test data.
- **Not doing:** iOS (needs a Mac and a paid Apple account), real forwarding from a Malaysian SIM (a +60 number needs
  company registration), deepfake detection, Cantonese or Hokkien, job and trafficking-recruitment scams (mostly over messaging; a
  later script pack).

**The 3-minute demo:** a spoofed "PDRM" number calls grandma, and Truecaller trusts it. The scammer goes through the script
in Manglish. At "safe account", her screen shows **"Letak telefon"** and her son's phone buzzes. The scammer says "ignore
your phone app", which does nothing. She opens the bank app and **the transfer is held**. Then a real bank call comes
through with no false alarm. We finish on our evidence table.

## 4. How we prove it works (judged by data, not by us)
- **Malaysian test set:** real scam recordings (PDRM and CCID clips, news, victim uploads), court judgments quoting
  scripts, and genuine bank and courier calls. Labelled by stage, with a second person checking.
- **Public benchmark:** the TeleAntiFraud-28k binary test (Mandarin scam calls, Apache 2.0). In the paper
  (arXiv:2503.24115, Table 4) published systems score 51 to 85 weighted F1 on fraud detection.
- **Targets, fixed before we build:**

| Target | MVP |
|---|---|
| Scams caught before the money stage | at least 90% |
| False alarms on genuine calls | at most 1 per 10 hours |
| Warning after the trigger line | within 2 s |
| TeleAntiFraud-28k binary test (Macro-F1) | at least 0.75 |
| Completed transfers in our role-play trial | 0 |

Judging criteria: impact 30%, use of Meta AI tools 25%, demo 25%, technical depth 20%.

## 5. The repo (scaffolded locally; goes on GitHub on 26 Oct)
```
jaga/
├─ AGENTS.md / CLAUDE.md     # rules for humans AND AI agents (Claude Code and Copilot both read them)
├─ GLOSSARY.md               # the words we use (stage, escalation, Jaga line, Jaga Pause...)
├─ docs/plan.md              # the full plan (this brief is its summary)
├─ docs/adr/                 # decisions: Android only, Jaga line, Meta models for AI, pinned toolchain,
│                            #   rules alone only raise a Caution, the user sees only fixed phrase-library text
├─ docs/spec.md             # the spec; 26 tickets are GitHub Issues #1-#26 (one lane each, with "blocked by")
├─ contracts/                # JSON schemas the app and server agree on (stage update, family alert, pause)
├─ app/                      # Flutter: Android app + Demo Bank (web)          → Lane B (Preston), Demo Bank Lane D
├─ server/                   # Python FastAPI: telephony, listening, rules, AI   → Lane A (Qi Cai), tools + pause Lane D
├─ eval/                     # test sets, replay harness, metrics               → Lane C
├─ .claude/                  # agents, skills, safety hooks (shared by Copilot too)
└─ .github/                  # CI, APK build, PR template, code owners
```
**Same versions on every machine:** Flutter **3.47.7** (via FVM), Python **3.13** and uv **0.12.24**, with lock files for
every package (`pubspec.lock`, `uv.lock`, `skills-lock.json`). The server runs in the **same Docker image** locally and in
production. Line endings are forced to LF so Windows and Mac don't fight.

**Stack:** Flutter (Android) · FastAPI on Render · Firebase (push notifications, auth) · Twilio (calls) · Meta Model API
(Muse Voice Transcribe, Muse Spark, SAM 3.1).

**Deploy and wake step:** the server runs on Render Free (`render.yaml`, auto-deploys from `main` once CI passes; no repo
secret). It spins down after 15 minutes without inbound traffic and takes about a minute to wake, but Twilio's voice
webhook gives up after 15 seconds, so a sleeping server fails the first call. Before a call or demo, hit `/health` and
wait for the JSON 200 (there is no keep-awake pinger, on purpose):
```powershell
$u = 'https://jaga-server.onrender.com'; $t = Get-Date
do { try { $ok = (Invoke-RestMethod "$u/health").status -eq 'ok' } catch { $ok = $false }; if (-not $ok) { Start-Sleep 3 } } until ($ok)
"awake after $([int]((Get-Date) - $t).TotalSeconds) s"
```
Calls, stage timelines and Jaga Pause state live in memory, so a spin-down or restart (including setting an
environment variable) loses them. This is accepted for the hackathon.

**AI-assisted workflow (works with Claude Code or GitHub Copilot):**
- Shared skills: **Matt Pocock's skills** (spec, tickets, implement, TDD, code review, PR, handoff), **Ponytail** (smallest
  code that works), and official **Flutter** and **FastAPI** skills.
- Subagents: cheap `scout` and `scribe` for reading and writing; `flutter-dev`, `server-dev` and `eval-dev` for coding;
  `reviewer` before every PR; `architect` for rare design changes. Copilot gets mirrors of the main ones.
- **Git rules:** one ticket, one branch (`<name>/<ticket>-<slug>`), one PR. Rebase on `main` first. CI must be green and
  the folder owner approves. Each person stays in their lane's folder, so we basically never conflict. Dependency and
  contract changes go in their own PRs.

## 6. Who does what (lanes)
Lanes C and D are interchangeable between Foon and Joshua. Tell me your pick.

| Lane | Who | Folder | Your job |
|---|---|---|---|
| **A. Core pipeline + lead** | **Qi Cai** | `server/` core, `contracts/` | Twilio audio in, live transcription, the script tracker, Muse Spark escalation, sending stage updates to the app, merging and unblocking everyone |
| **B. The app** | **Preston** | `app/` | Receiving calls in the app (`twilio_voice`), the warning screen (big command, counter-move), family mode with push alerts, onboarding, 3 languages, elderly-friendly design |
| **C. The evidence** | **Foon / Joshua** | `eval/` | Build the test sets, labelling, the replay harness, run the TeleAntiFraud benchmark, produce the numbers for the demo |
| **D. Product edges + shipping** | **Joshua / Foon** | `server/jaga/tools`, `server/jaga/pause`, Demo Bank, CI | Scam-phrase library in 3 languages, official-hotline table, mule-account mock, Jaga Pause and the Demo Bank, golden-hour report, CI and deployment, the demo video |

**Tickets are ready:** 26 of them in GitHub Issues (#1 to #26), each one lane, with "blocked by" links.
Day-1 starters with no blockers: A `001` contracts, `002` telephony test; C `003` transcription test, `005` corpus; D `004`
CI and deploy, `006` phrase library. Lane B starts on `009` to `011` as soon as `001` (contracts) lands.

## 7. What you can research **now**, before 26 Oct
**No product code before kickoff.** The Official Rules aren't out yet. Reading, notes, accounts and sample data are fine.

**Everyone:**
- [ ] Read `docs/plan.md` (10 min) and Meta's docs: dev.meta.ai/docs (speech-to-text, Muse Spark tools and structured output).
- [ ] Install the toolchain (section 8) and the Matt Pocock skills plugin for your AI tool.
- [ ] Skim how Macau scam calls actually sound: search YouTube for "Macau scam call recording Malaysia" or PDRM awareness clips.

**Qi Cai (A):** Twilio Media Streams (`<Start><Stream track="both_tracks">` plus `<Dial><Client>`), the Muse Voice
Transcribe realtime WebSocket protocol, converting 8 kHz mu-law audio to 16 kHz PCM, Muse Spark tool calling and
structured output, prompt-injection defences.

**Preston (B):**
- `twilio_voice` on pub.dev: incoming calls on Android (ConnectionService, Firebase setup, Android 14/15 permissions such as
  full-screen intent and foreground-service types).
- FCM data messages, and a WebSocket client in Flutter.
- `flutter_localizations` (Malay, English, Mandarin).
- Accessibility for elderly users: large text and high contrast.

**Lane C:**
- Collect candidate **scam recordings and transcripts** (PDRM and CCID YouTube, news sites, Malaysian court judgments on
  CommonLII that quote scam calls).
- Find **genuine bank and courier call examples**.
- Write a usage note per source.
- Read the TeleAntiFraud-28k paper (arXiv 2503.24115) and dataset (Hugging Face `JimmyMa99/TeleAntiFraud`, Apache 2.0),
  plus TeleAntiFraud 2.0 (arXiv 2609.18748).
- Look up WER (`jiwer`), Cohen's kappa and bootstrap confidence intervals.

**Lane D:**
- Draft the **scam-phrase list** in Malay, English and Mandarin (from PDRM, NSRC and Semak Mule advisories).
- Draft the **official hotlines table** (PDRM, LHDN, Bank Negara, major banks, NSRC 997).
- Check whether PDRM **Semak Mule** has any public API.
- Create the **Firebase** and **Render** accounts (free tiers).
- Storyboard the demo video.
- Plan the Truecaller head-to-head (a phone with Truecaller receiving our "PDRM" call).

## 8. Setup checklist (do before 26 Oct)
1. Install: **Git**, **FVM 4.3.1** (Windows: the standalone zip, no Chocolatey needed), **Android Studio** (SDK and an emulator; or the command-line tools plus **Temurin JDK 21**), **uv 0.12.24**,
   **Docker Desktop**, **GitHub CLI** (`gh auth login`). Exact commands are in the repo `README.md`.
2. AI tool plugin:
   - Claude Code: `claude plugin install mattpocock-skills@claude-plugins-official`
   - Copilot: `copilot plugin marketplace add mattpocock/skills`, then `copilot plugin install mattpocock-skills@mattpocock`
3. Send Qi Cai your **GitHub username** (for repo access and code owners).
4. Have an Android phone or emulator that can install an APK. Xiaomi/Redmi/POCO phones need **Install via USB** turned on
   in Developer options; the emulator is the easy option.

## 9. Timeline
| Date | What happens |
|---|---|
| **Before 26 Oct** | Research (section 7), installs (section 8), GitHub usernames |
| **26 Oct** | Kickoff. Read the Official Rules. Repo goes live, tickets go up, contracts finalised. First tests of the phone line and transcription |
| **27 to 29 Oct** | First full call with a warning (first on fake data, then on real APIs) |
| **30 Oct to 1 Nov** | Tools, family alert, Jaga Pause, evaluation numbers |
| **2 to 3 Nov** | Stretch features, polish. **Feature freeze 3 Nov** |
| **4 Nov** | Demo video and submission (due 9 PM ET = 5 Nov 9 AM MYT) |

Daily: a 10-minute sync (what's merged, what's blocked) and `/handoff` before you stop.
