# eval/ (evidence that Jaga works, judged by data, not by us)

- `jaga_eval/` imports the real pipeline from `jaga` (the server package). Never reimplement pipeline logic here.
- Committed: `data/manifest.csv` (source, link, licence or usage note, split) and `data/labels/`. Not committed: audio
  (`data/audio/`, gitignored). Record a usage note for every source.
- Split by **source**, never by random row, so test calls never leak into development.
- Metrics: transcription error rate (vs human transcripts), time to warning, recall before the `money` stage, false alarms
  per hour of genuine calls, p50/p95 latency, cost per call, with bootstrap confidence intervals.
- Targets are fixed in `docs/plan.md`. Report misses honestly; never tune on the held-out set.
- TeleAntiFraud-28k (`python -m jaga_eval.teleantifraud <test.json>`): Hugging Face JimmyMa99/TeleAntiFraud, Apache-2.0,
  gated access. Files stay in `data/teleantifraud/` (gitignored); never log transcript text. The full per-call report is
  `reports/teleantifraud.local.json` (untracked); only the numbers-only `reports/teleantifraud.md` is committed.
- Replay harness (`python -m jaga_eval.replay <calls.json> [--transcriber muse|fake] [--spark meta|fake|open|off] [--speed X]`):
  recorded calls go through the Twilio Media Streams seam in 20 ms mu-law chunks at real-time speed. `muse`/`meta` use
  the real APIs (needs `META_API_KEY`, paid); `fake` replays the call's `script` lines for cheap runs. Family alerts go
  to a recording fake, never a real push. The per-call report (stage updates, alerts, timings) holds masked quotes, so
  it is `reports/replay.local.json` (untracked); never print or commit it. It refuses held-out rows: those
  go only through the metrics report's `--final`.
- Metrics report (`python -m jaga_eval.report <calls.json> [--arms rules rules+spark rules+open spark-only]`): the plan
  targets with n and bootstrap CIs, written numbers-only to `reports/metrics-<split>.md`. Each call carries `label`
  (scam|genuine) and `split` (dev|heldout, required: any other value is refused) in calls.json. Held-out runs need `--final`; one run,
  never read the misses to change rules, prompts or thresholds. `rules+open` needs `BASETEN_API_KEY`/`BASETEN_BASE_URL` (Muse Spark Open);
  prices (`--spark-usd`, `--open-usd` for the rules+open arm, `--asr-usd-per-min`) are inputs, so cost is "n/a"
  unless given. Optional `moneyAt` (second of the caller's first money/credentials line) grades Caught on paced runs.
