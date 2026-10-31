# Annotation guide: Jaga call stages

Stage names and order come from the repo's `GLOSSARY.md` and `docs/spec.md`. Definitions below are inferred from those names and the Macau script; confirm them against the stage tracker's rule table (lane A) before the second labeller starts.

Label **every line** with exactly one stage. Lines are already segmented in the sheet; do not split or merge them. Label what the line *does* in the call, not what it is about. Work from the text and this guide only.

Severity order: `none` < `pretext` < `authority` < `fear` < `isolation` < `handoff` < `money` = `credentials`.

| Stage | Use when the line... | Example |
|---|---|---|
| none | does none of the below: greetings, filler, the victim's replies, challenges, garbled text, genuine-call lines | "What court case?" |
| pretext | states the made-up problem or reason for calling (debt, parcel, unpaid tax, money laundering case) | "Anda mempunyai tunggakan cukai." |
| authority | claims or backs up an identity or agency (bank, LHDN, PDRM, court, BNM, staff ID) | "Saya dari pegawai bank." |
| fear | threatens or pressures (arrest, warrant, court, service cut, deadline) | "Waran tangkap akan dikeluarkan." |
| isolation | tells the victim to keep it secret or ignore outside help (including ignoring an app or the bank) | "Jangan beritahu sesiapa." |
| handoff | passes the victim to another "officer" or agency | "Sila tekan sembilan untuk bercakap dengan pegawai kami." |
| money | asks for money, a deposit, a transfer, or moving funds to a "safe account" | "Pindahkan baki ke akaun selamat." |
| credentials | asks for secrets: IC, account or card number, password, TAC/OTP, other accounts | "Sila baca nombor TAC." |

## Rules
1. **One label per line.** If a line fits two stages, pick the more severe one (order above; money and credentials tie, pick the one the line mainly asks for).
2. **Victim lines are `none`**, even when they repeat or test the scammer's words. Exception for the full pipeline: a protected-user line that discloses a TAC, account number or IC counts as `credentials`. The current transcripts have no caller/user split, so label such lines `credentials` only if the text clearly shows the victim handing the data over.
3. **Genuine calls use the same sheet.** Their lines are `none`, even when they claim an identity or ask to confirm something, unless the line truly matches a stage above. Note any doubt in `notes`.
4. **Unreadable or garbled text:** label your best guess and write `unclear` in `notes`. Do not skip the line.
5. **Investment-style lures** (high returns, "limited slots") have no stage of their own in Jaga, which ships the Macau script pack only. Label them `pretext` and keep them flagged as out-of-pack.
6. Do not discuss labels with the other labeller until both sheets are submitted.

## Change log
- v1 used my own stage names (IMPERSONATION, PRETEXT, URGENCY_THREAT, ESCALATION, DATA_REQUEST, MONEY_TRANSFER, LURE, NO_STAGE). Replaced by the repo's stages: authority, pretext, fear, handoff, credentials, money, pretext (LURE), none. `isolation` was added; the corpus has no isolation lines yet.
- (Record every wording change after reviewing disagreements, with date and reason.)
