# Glossary

Seed list. `/grill-with-docs` extends it. Use these words in code, tickets and PRs.

| Term | Meaning |
|---|---|
| **Protected user** | The person Jaga guards, usually an elderly parent. Their calls ring in the Jaga app |
| **Family co-pilot** | A trusted contact who gets alerts about one protected user, can phone them from the alert, and is the only one who can clear Jaga Pause early. Same app, `family` role |
| **Jaga line** | The telephony number the protected user's SIM forwards calls to. It rings the app and forks the audio to the server |
| **Voice access token** | What lets the protected user's app register to ring on the Jaga line's calls. Short-lived, and it can receive calls but never place them |
| **Leg** | One side of a call's audio: `caller` or `user` |
| **Stage** | Where the caller is in the scam script: `pretext`, `authority`, `fear`, `isolation`, `handoff`, `money`, `credentials`. A call's stage is the most severe one seen so far and never goes down; `money` and `credentials` tie as most severe. `none` means no signs yet |
| **Region pack** | Everything country-specific: script packs, official contacts, scam hotline, languages, keywords and default command language. The MVP ships Malaysia only |
| **Script pack** | One scam script's stages, hard triggers and phrases, inside a region pack. Malaysia ships the Macau pack only |
| **Stage tracker** | The free, deterministic rule layer that assigns stages from transcript turns |
| **Genuine call** | A real, non-scam call, such as a bank card check or a courier. Every evaluation set includes them |
| **Caught** | A scam call where a Warning appeared before the caller's first `money` or `credentials` line |
| **False alarm** | A Warning on a genuine call. A Caution on a genuine call is not one |
| **Escalation** | Calling Muse Spark because the rules fired or the call is ambiguous |
| **Risk** | How likely the call is a scam right now: `low`, `medium` (Caution) or `high` (Warning). Unlike stage, it can go down |
| **Caution** | The quiet banner shown at medium risk ("This call has signs of a scam"). No command |
| **Warning** | The high-risk screen: command first, then counter-move and evidence. Only shown at high risk |
| **Hard trigger** | A phrase so specific to scams (e.g. "akaun selamat", a TAC request) that the rules raise a Warning without waiting for Muse Spark |
| **Command** | The single instruction shown first in a warning ("Letak telefon. Hang up.") |
| **Counter-move** | The coached next step that breaks the scam, e.g. "say you'll call back, then phone the station's official number" |
| **Phrase library** | The fixed, reviewed text for every command and counter-move, per stage and language. Nothing else is shown to the protected user |
| **Phrase ID** | The stable ID of one library entry, e.g. `my.fear.command` or `my.fear.counter.1`. Muse Spark picks a counter-move by phrase ID, never by free text |
| **Official contact** | A region pack's source-noted number for an agency (997, PDRM, LHDN, Bank Negara, the main banks), read with `official_contact(region, agency)`. Never invented |
| **Family alert** | A push to a protected user's family co-pilots about one call: an alert when the call reaches `isolation`, then `money` or `credentials`, or a "may be genuine" follow-up when Muse Spark lowers a Warning. A summary, never the transcript |
| **Link code** | The code shown at setup that a family co-pilot enters to follow a protected user |
| **Stage timeline** | What's kept after a call: stages, times, risk changes and masked evidence quotes. Never the transcript or audio |
| **Jaga Pause** | Bank-facing signal: "is this customer mid-scam?". The Demo Bank uses it to hold a transfer |
| **Pause token** | What a protected user gives their bank at onboarding so the bank can ask Jaga Pause about them |
| **Golden-hour pack** | Post-call report for the region's scam hotline (997 in Malaysia) or the bank, with timeline, number, mule account and quotes |
| **Replay harness** | Streams recorded call audio through the real pipeline at real-time speed, for evaluation |
| **Fake** | A stand-in for a Meta or Twilio client that returns recorded or canned data |
