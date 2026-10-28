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
