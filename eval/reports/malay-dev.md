# Malay development set: rules and rules+Spark (#25)

Numbers only, run on 3 Nov 2026 on cached Muse transcripts (no new transcription). Three arms:
- **rules:** `python -m jaga_eval.report calls.local.json --arms rules` (Spark off, unpaced), copied from
  the `metrics-dev.md` it wrote.
- **rules+Spark, 2.5 s:** the server as deployed, with Muse Spark and the server's 2.5 s Spark timeout. 20 paid
  Spark asks.
- **rules+Spark, 6 s (eval only):** the same, with the Spark timeout raised to 6 s in the run script only (the
  server still uses 2.5 s). 20 paid Spark asks.

Both Spark runs use `report.py`'s `run_arm` and `metrics`, through a local script that sends one line per
second, adds 15 s of silence at the end and times each Spark answer. Time to Warning came from a
separate paced replay. That replay is not `report.py`'s time to Warning, which needs a labelled trigger
line, so `report.py` does not reproduce it.

**This is a development-set number, not held-out.** The `my.json` phrases were widened after hearing some
of these recordings, so the scores are optimistic for unseen calls.

## For the video

Malay dev set: 10 read scam scripts and 10 genuine calls. Jaga as deployed: rules plus Muse Spark (2.5 s
timeout).

| Measure | Target (plan.md) | Jaga | n |
|---|---|---|---|
| Scams caught before money | ≥ 90% | 50% (95% CI 20% to 80%) | 10 scam calls |
| False alarms per 10 h of genuine calls | ≤ 1 | 3.6 (1 in 2.78 h; CI 0 to 11) | 10 genuine calls |
| Time to Warning, p95 | ≤ 2 s | not measured end to end (rules decide in 0.002 s once a line is transcribed) | 7 Warnings |
| TeleAntiFraud-28k Macro-F1 (Mandarin, all-normal baseline: no Mandarin pack yet, #36) | ≥ 0.75 | 0.333 (CI 0.312 to 0.356) | 400 calls |

The 6 s timeout run (eval only) changed nothing: Spark answered all 20 asks, and every call reached the
same stages and Warnings as with rules alone. On TeleAntiFraud every call ended at stage `none`, so no
fraud was caught. See `teleantifraud.md`.

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

## Results

| Metric | n | rules | rules+Spark, 2.5 s | rules+Spark, 6 s (eval only) | MVP |
|---|---|---|---|---|---|
| Scams caught before `money` | 10 | 50.0% [20.0%, 80.0%] | 50.0% [20.0%, 80.0%] | 50.0% [20.0%, 80.0%] | missed |
| False alarms per 10 h genuine (1 in 2.78 h) | 10 | 3.6 [0, 11] | 3.6 [0, 11] | 3.6 [0, 11] | missed (CI spans the target) |
| Genuine calls with only a Caution | 10 | 1 | 1 | 1 | |
| Spark asks | 20 calls | 0 | 20 | 20 | |
| Spark failures (all timeouts) | | | 11 of 20 | 0 of 20 | |
| Spark answer time p50 / p95 (s) | answered asks | | 2.09 / 2.48 (n=9) | 2.42 / 4.16 (n=20) | |
| Rules decision after the line, p50 / p95 (s) | 7 Warnings | 0.001 / 0.002 | | | not end to end |

- **Spark changed no outcome on this set.** In both Spark runs every call had the same stage sequence and
  the same Warnings as with rules alone, even at 6 s, when Spark answered every ask. At the deployed 2.5 s,
  Spark timed out on 11 of 20 asks; the server then keeps the rules' answer (fail-safe Warning at `money` or
  `credentials`).
- Spark answer times are close to the 2.5 s limit (p95 2.48 s of the answered asks), and at 6 s p95 is 4.16 s.
  These times cover only the answers that came back, not the asks that timed out.
- Caught is graded against the first `money` or `credentials` stage the arm detected: cached transcripts
  carry no timestamps, so 0 of 10 are graded against a labelled line. A Warning raised by the money line
  itself is late. 1 of the 5 caught (rec_07) counts as caught with no money line detected, so a money line
  the rules miss would inflate this number.
- 7 of 10 scams got a Warning; 2 of those only at the money line. 3 scams never got past `none` or
  `authority`, so the `my.json` phrases, not Spark, limit the score here.
- Rules decision time: the scam transcripts were replayed one sentence per second, and the time is the
  Warning minus the sending time of the sentence that raised it, over all 7 Warnings (late ones included).
  Transcription is not in it, so it does not show the ≤ 2 s target is met end to end.
- **A first paid rules+Spark run was discarded.** It sent all lines at once. When the stream stops, the
  server waits only 5 s for lines still in its queue, so slow Spark asks cut most scam calls short, and
  the cut asks were counted as timeouts. Only its latency is kept: p50 2.14 s, p95 2.45 s over its 5
  answered asks, which agrees with the paced runs.
- Cost per call: n/a (no prices given). Transcription error rate: not scored here (see #69).
