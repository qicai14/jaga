# 0002: The Jaga line (calls ring inside our app)

**Decision:** the protected user's SIM forwards calls to a Twilio number. Twilio forks both legs' audio to our server
(Media Streams) and rings the user's Jaga app (Voice SDK via `twilio_voice`).
**Why:** Android 10+ and iOS give third-party apps no access to cellular call audio, even on speaker. Hiya uses forwarding too.
**Demo:** a US Twilio number, called directly. **Production:** a +60 number (SSM and MCMC review) or a telco partnership.
Malaysian forwarding is domestic only and charged per minute.
**Verify on day 1:** `<Start><Stream track="both_tracks">` plus `<Dial><Client>`, connect time, and transcription quality on
8 kHz mu-law audio upsampled to 16 kHz PCM.
