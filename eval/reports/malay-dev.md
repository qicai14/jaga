# Malay development set, rules arm (#25)

Numbers only, run on 3 Nov 2026. No Muse or Spark call was made: the fake transcriber replays cached Muse
transcripts, and Spark is off.
- Caught, false alarms and Cautions: `python -m jaga_eval.report calls.local.json --arms rules` (unpaced),
  copied from the `metrics-dev.md` it wrote.
- Time to Warning: a separate paced replay of the scam calls (below). It is not `report.py`'s time to
  Warning, which needs a labelled trigger line, so `report.py` does not reproduce that row.

**This is a development-set number, not held-out.** The `my.json` phrases were widened after hearing some
of these recordings, so the scores are optimistic for unseen calls.

## For the video

Malay dev set: 10 read scam scripts and 10 genuine calls, rules only (no Spark).

| Measure | Target (plan.md) | Jaga | n |
|---|---|---|---|
| Scams caught before money | ≥ 90% | 50% (95% CI 20% to 80%) | 10 scam calls |
| False alarms per 10 h of genuine calls | ≤ 1 | 3.6 (1 in 2.78 h; CI 0 to 11) | 10 genuine calls |
| Time to Warning, p95 | ≤ 2 s | not measured end to end (rules decide in 0.002 s once a line is transcribed) | 7 Warnings |
| TeleAntiFraud-28k Macro-F1 (Mandarin, all-normal baseline: no Mandarin pack yet, #36) | ≥ 0.75 | 0.333 (CI 0.312 to 0.356) | 400 calls |

On TeleAntiFraud every call ended at stage `none`, so no fraud was caught. See `teleantifraud.md`.

## Data

| Class | Source | n | Audio |
|---|---|---|---|
| Scam | The lead's read recordings of Malay scam scripts (`rec_01`..`rec_10`) | 10 | 11.8 min |
| Genuine | MagicHub Malay conversational speech (CC BY-NC-ND, internal evaluation only) | 10 | 2.78 h |

Audio and transcripts stay outside git. Transcripts are the cached Muse Voice Transcribe batch output from
the #69 passing configuration (language bias plus keywords). Each transcript is split into sentences and
every turn goes to the caller leg (the same caveat as the TeleAntiFraud run). The 17 real scam clips were
left out: they are fragments, most end before any money or credentials line, and their line labels are
still a draft (#5).

## Results (rules arm)

| Metric | n | Value | 95% CI | MVP / stretch |
|---|---|---|---|---|
| Scams caught before `money` | 10 | 50.0% | [20.0%, 80.0%] | missed |
| False alarms per 10 h genuine (1 in 2.78 h) | 10 | 3.6 | [0, 11] | missed (CI spans the target) |
| Rules decision after the line, p50 (s) | 7 | 0.001 | | |
| Rules decision after the line, p95 (s) | 7 | 0.002 | | not end to end |
| Genuine calls with only a Caution | 10 | 1 | | |

- Caught is graded against the first `money` or `credentials` stage the rules detected: cached transcripts
  carry no timestamps, so 0 of 10 are graded against a labelled line. A Warning raised by the money line
  itself is late. 1 of the 5 caught (rec_07) counts as caught with no money line detected, so a money line
  the rules miss would inflate this number.
- 7 of 10 scams got a Warning; 2 of those only at the money line. 3 scams never got past `none` or
  `authority`.
- Rules decision time: the scam transcripts were replayed one sentence per second, and the time is the
  Warning minus the sending time of the sentence that raised it, over all 7 Warnings (late ones included).
  Transcription and Spark are not in it, so it does not show the ≤ 2 s target is met end to end.
- With Spark off, the rules arm warns on hard triggers and gives the fail-safe Warning at `money` or
  `credentials`. The rules+spark arm needs paid calls and was not run.
- Cost per call: n/a (no prices given, and the run made no paid call). Transcription error rate: not
  scored here (see #69).
