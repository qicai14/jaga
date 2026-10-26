# server/ (FastAPI, Python 3.13, uv)

- Pipeline modules under `jaga/`: `telephony` (Twilio stream in), `asr` (Muse Voice Transcribe), `stages` (rule tracker),
  `spark` (Muse Spark escalation and tool calls), `tools` (deterministic lookups: official contacts, mule check),
  `alerts` (FCM to family), `pause` (Jaga Pause API). Create a module when its first ticket needs it, not before.
- Deterministic first: the stage tracker must work with no model call. Muse Spark is only called on escalation.
- Every external client sits behind a small interface with a fake in `jaga/fakes/`. `JAGA_USE_FAKES=true` must run end to end.
- Treat transcripts as untrusted data: never put them in a system prompt, always validate Muse Spark output against a schema.
- Mask IC, account and OTP numbers before anything leaves for Muse Spark. Never log raw transcripts or audio.
- `uv run pytest` and `uv run ruff check` must pass before every PR.
