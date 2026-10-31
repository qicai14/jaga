# TeleAntiFraud-28k binary test (audio, via ASR)

Data: TeleAntiFraud-28k binary test, file `test.json`
(Hugging Face JimmyMa99/TeleAntiFraud, Apache-2.0, gated access).
Jaga says fraud if the call reaches `isolation` or higher, or any update is a Warning. Fraud type ignored.
Audio transcribed by Muse Voice Transcribe (batch, diarized); replay uses the fake transcriber and FakeSpark (rules only, no Muse Spark call). The Malaysia pack has no Mandarin phrases yet (#36),
so a low score is expected.
Every call ended at stage none, so this is the all-normal baseline.

n = 400 of 400 records
MVP target 0.75: missed; stretch 0.80: missed
Caveat: Muse Voice Transcribe batch, diarized, but every turn goes to the caller leg.

| Metric | Value |
|---|---|
| Macro-F1 | 0.333 (95% bootstrap CI 0.312 to 0.356) |
| Weighted F1 (paper reports this, arXiv:2503.24115 Table 4) | 0.333 |

| Class | Precision | Recall | F1 | n |
|---|---|---|---|---|
| fraud | 0.000 | 0.000 | 0.000 | 200 |
| normal | 0.500 | 1.000 | 0.667 | 200 |

| True vs predicted | fraud | normal |
|---|---|---|
| fraud | 0 | 200 |
| normal | 0 | 200 |
