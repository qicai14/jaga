# Jaga app UI plan (Lane B)

Agreed with Preston on 27 Oct 2026 in a grilling session (32 decisions). Terms follow `GLOSSARY.md`. Per-feature
design briefs (`app/design/<feature>.md`) are written by `b-architect` from this plan before any screen is coded.

## 1. Principles
- **One app, two roles.** First launch asks "Who is this phone for?": protected user or family co-pilot. The role is
  fixed for the install; switching means a PIN-protected reset (protected) or unlink (co-pilot).
- **No login anywhere.** Firebase Anonymous Auth runs silently; the link code is the only bond between phones.
- **Calm every day, loud once.** Warm off-white background, deep teal/green "guarded" colour, big type in Noto Sans (chosen for its Latin and Chinese coverage).
  Caution is amber, Warning is full-screen solid red, the family "may be genuine" follow-up is calm blue. Light theme
  only.
- **Elderly-first.** Body ≥ 20sp, touch targets ≥ 56dp, WCAG AAA contrast. Honour Android's system font size and work
  at 2×. The Warning command always fits without scrolling (it shrinks to no less than ~32sp).
- **Three languages.** ms, en, zh via `flutter_localizations`. Bundled Noto Sans and Noto Sans SC
  (subsetted). The protected phone's **app language** is its **command language**; a co-pilot picks their own (default:
  the phone's language).
- **Portrait Android phone only**, 360–412dp wide.

## 2. Protected user (grandma's phone)

### Onboarding (#10), done by the co-pilot on grandma's phone
1. Role
2. Command language (Malay preselected; options shown in their own script)
3. Region: Malaysia, shown for information only
4. Phone permissions checklist: a live green tick per item, and a "Fix" button opening the right Android settings page
   (phone account, notifications, full-screen intent, Xiaomi autostart)
5. Call forwarding: shows the code, and "Dial now" opens the dialer prefilled with `*21*<Jaga line>#`
6. Set the co-pilot lock PIN
7. Pause token: Copy and Share, plus "Give this to your bank so it can hold transfers during a scam call"
8. Link code: 6 digits in big type with Share (no QR)
9. "Feel the buzz": plays the Warning vibration once and explains it means "look at the screen"
10. Done, then the status screen

### Status screen (home)
A big "Jaga is protecting you" with a green check, and the names of her co-pilots. Nothing else. Settings (language,
forwarding, pause token, reset) sit behind a long-press plus the co-pilot lock PIN.

### Call screen (#12)
Our own Flutter screen once a Jaga line call connects: caller number, timer, mute, speaker and hang up (no hold). The
Caution and Warning are layers on this screen. **Fallback**, if the #12 telephony test shows `twilio_voice` can't host
it: Android's own call screen, with the Warning as a full-screen notification opening the same Warning widget.

### Caution and Warning (#9, live in #19)
| Risk | What she sees |
|---|---|
| low | Nothing extra |
| medium | An amber **Caution** banner at the top of the call screen. No command |
| high | A full-screen red **Warning**: the **command** first (command language, then English), then the **counter-move** with the official number as big text (not a button), then one short evidence line (none on the credentials Warning), then a big **Hang up** button she presses herself |

- **Buzz:** a distinctive vibration pattern that repeats until she looks, since the screen is off at her ear. No sound
  into the call.
- **Dismiss:** a small "Panggilan ini selamat / This call is fine" button at the bottom, held for ~2 s. It hides the
  Caution or Warning on her screen only, until the stage or risk gets worse, and then it comes back.
- **Risk goes down:** a Warning steps down to the Caution banner, and a Caution disappears. She never sees a "safe" message.
- **Credentials:** if she starts reading out a TAC, account number or IC, the same Warning screen shows a different command.
- **Missing phrase** in her language: show the English one.
- **Stream drops:** freeze what's shown, show a tiny grey "reconnecting" dot, and reconnect silently.
- All on-screen command and counter-move text comes from the phrase library (ADR 0006). Whether the app holds the
  phrases or the server sends finished text is decided in contracts #1; the screens just display what they're given.

### After the call
- **A call with a Warning:** about 10 s of reassurance, "You did the right thing. [Name] has been told", plus a big
  "Call [agency]'s real number" button. No details.
- **A genuine call:** nothing.

## 3. Family co-pilot (their own phone)

### Onboarding
1. Role
2. App language
3. Enter the 6-digit link code. With 3 co-pilots already linked, it explains why they can't join.
4. Allow notifications
5. Done, then the home screen

### Alert (#11)
- **Notification:** a high-priority heads-up notification on the lock screen, with sound and a **"Call [Mum]"** action.
- **Alert screen:** tapping it opens the name, stage (plain label plus a 6-step progress bar), claimed agency, summary,
  at most 2 masked quotes, and a big Call button.
- **"May be genuine" follow-up:** the same layout in calm blue.
- **Takeover:** the alert never takes over the co-pilot's full screen.

### Home, timeline and Jaga Pause (#23)
- **Protected user card:** "Mum: protected", with a **Jaga Pause active** badge while the pause is on.
- **Clear Jaga Pause:** on the card, and only while the pause is active. It opens a confirmation ("I've spoken to Mum
  and checked this transfer is genuine") and then a hold-to-confirm.
- **Alerted calls:** a list of the last 30 days, one entry per call that alerted. Each opens its **stage timeline**,
  which has Delete and a **"Call 997"** button. Genuine calls are never shown.
- **Stage labels:** plain words instead of jargon ("Told to keep it secret", "Asked to move money"), in all 3 languages.
- **Settings:** app language and unlink.

## 4. Architecture (flutter-apply-architecture-best-practices + `app/AGENTS.md`)
```
lib/
  core/       theme/ (tokens, ThemeData, fonts), l10n/, widgets/ (big button, hold-to-confirm, stage bar…)
  data/       models/ (typed from contracts/; the only layer that changes when contracts v1 lands)
              services/ (stage stream, FCM, twilio_voice, Firebase), repositories/
  features/   onboarding/ call/ warning/ family/ (each: views/ + view_models/, ChangeNotifier MVVM)
  debug/      gallery: every screen in every state from fixtures (debug builds only)
```
We build now on the **draft v0 contracts** with mock data. When #1 merges, only `lib/data/models/` and the fixtures
change.

## 5. How we review and test
- **Per feature:** `b-architect` writes the brief, Preston OKs it, `b-flutter-dev` builds it, Preston reviews it in the
  **debug gallery** on the emulator, then fixes, then `b-tester`, `reviewer` and the PR.
- **Widget tests:** every screen and state at 393×852 and at text scale 2.0, using the gallery's fixtures.
- **Emulator only for now** (no physical phones yet):
  - Run **two emulators** at once, one per role, for the alert flow. Use Play Store system images for FCM.
  - Simulate proximity with the emulator's virtual sensors.
  - Vibration can't be felt: test that the pattern is triggered, and check it on a real phone later.
- **Before the demo:** borrow one or two Android phones from the team to test the buzz, the screen at the ear,
  lock-screen notifications and OEM background limits.

## 6. Build order (feature freeze 3 Nov)
1. Design system: theme, fonts, l10n, shared widgets, gallery shell
2. Caution and Warning (#9)
3. Family alert (#11)
4. Onboarding (#10)
5. Call screen (#12, after #2 lands; decides call screen vs fallback)
6. Live stage stream (#19)
7. Timeline and Clear Jaga Pause (#23)
8. Polish: app icon (simple shield, hand-made adaptive icon) and the after-call reassurance screen

## 7. Open dependencies (not ours to decide)
- **#1 contracts v1** (Lane A): phrase IDs vs resolved text, the "may be genuine" alert kind, the stage-timeline shape,
  and the pause request.
- **#2 telephony test** (Lane A): blocks #12, and the call screen vs fallback choice.
- **Phrase library content** in 3 languages (Lane D), and the official contacts table (Lane D).
- **Physical test phones** (team).
- **`twilio_voice` vs our Android Gradle Plugin 9.1**: it targets AGP 8.9.1. Check with a test build in #12.

## 8. Decisions
- Tamil removed from the app (Preston, 28 Oct): project scope change. Languages are ms, en, zh.
