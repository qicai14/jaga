# 003: Day-1 transcription spike

Lane: C
Status: ready-for-agent
Blocked by: None (can start immediately)

**What to build:** Know whether Muse Voice Transcribe hears code-switched Malaysian speech well enough on 8 kHz phone audio.

- [ ] A handful of sample clips downsampled to 8 kHz mu-law, then converted to 16 kHz PCM, go through Muse Voice Transcribe with Malaysia's `languageBias` and keywords
- [ ] Error rate against human transcripts is recorded
- [ ] A go/no-go note, with what to try if quality is poor
