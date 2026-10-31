# 0003: Meta models for every AI step; anything for plumbing

**Decision:** hearing, seeing and reasoning use Meta models: Muse Voice Transcribe, Muse Spark, SAM 3.1, and Meta
open-weight models. Telephony, push, storage, CI and hosting can use any tool.
**Why:** "Use of Meta AI tooling" is 25% of judging. The waiver allows open source and third-party help; re-check the
Official Rules on 26 Oct.
**Privacy:** Standard mode only (never `-contributor` models), request zero data retention, mask IC, account and OTP numbers
before Muse Spark, store no audio.
**Zero data retention:** our Muse Spark calls send `store: false` on the Responses API, so we request no storage per call.
Account-level ZDR needs an enterprise account, which our personal dev.meta.ai account is not.
