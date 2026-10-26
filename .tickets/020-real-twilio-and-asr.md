# 020: Real Twilio and Muse Voice Transcribe

Lane: A
Status: ready-for-agent
Blocked by: 002, 007

**What to build:** The same scripted call, spoken into the real Jaga line, produces `stage-update` messages from real transcripts.

- [ ] Real Twilio Media Streams and Muse Voice Transcribe clients behind the same interfaces as the fakes
- [ ] 8 kHz mu-law converted to 16 kHz PCM
- [ ] Region pack's `languageBias` and keywords sent
- [ ] No audio or raw transcript is logged or stored
