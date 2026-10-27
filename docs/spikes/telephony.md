# Day-1 telephony spike (issue #2)

**Question:** does `<Start><Stream track="both_tracks">` plus `<Dial><Client>` give us both legs' audio and ring a
Voice SDK client fast enough for the Jaga line (ADR 0002)?

**Rig:** `server/jaga/spike.py`, deployed to Fly (`jaga-server`). The Twilio number and the TwiML App already point at
`POST /twilio/voice`. The Voice SDK client is the Twilio JS SDK in a browser at `/spike`, identity `spike`. Android
ringing through `twilio_voice` and FCM is the app lane's own day-1 test, not this one.

## Steps

1. Set the spike key and deploy this branch (from the repo root):
   ```bash
   fly secrets set JAGA_SPIKE_KEY=<any long random string> -a jaga-server --stage
   fly deploy . --config server/fly.toml --dockerfile server/Dockerfile
   ```
2. On a laptop with a headset, open `https://jaga-server.fly.dev/spike?key=<key>`. Wait for "Registered as 'spike'".
3. From a phone, call the Jaga line (`TWILIO_NUMBER`). Start a stopwatch when you press dial; stop it when the browser
   shows "Ringing". Click **Answer**, then talk on both ends for about 20 seconds, then hang up.
4. Open `https://jaga-server.fly.dev/spike/report?key=<key>`. Repeat for 3 calls in total.
5. Fill in the results and the decision below. Delete `JAGA_SPIKE_KEY` (`fly secrets unset`) when done.

## Reading the report

All times are seconds after Twilio hit `/twilio/voice` (one server clock):
`stream_start_s` (fork started), `incoming_s` (browser rang), `accepted_s` (answered), `stream_stop_s` (hung up).
`legs.caller` is the `inbound` track and `legs.user` the `outbound` track; `frames` should be about 50 per second of
call on each, and `voiced_bytes` well above zero on both means both people were heard. `first_at` on `user` should be
near `accepted_s` (Twilio plays ringback to the caller before that, which may also land on the outbound track).

## Results (27 Oct, 3 calls from a Malaysian mobile to the US Jaga number)

| Call | `incoming_s` (rang) | `stream_start_s` | `accepted_s` | caller frames / voiced bytes | user frames / voiced bytes |
|------|---------------------|------------------|--------------|------------------------------|----------------------------|
| 1    | 0.42                | 1.03             | 3.22         | 1015 / 156960 of 162400      | 959 / 100812 of 153440     |
| 2    | 0.35                | 0.82             | 2.88         | 994 / 155200 of 159040       | 934 / 106838 of 149440     |
| 3    | 0.56                | 0.81             | 2.11         | 984 / 157440 of 157440       | 994 / 132075 of 159040     |

- **Both legs arrive on every call:** `tracks` is `["inbound", "outbound"]`, and each leg gets about 50 frames of
  160 bytes per second (20 ms of 8 kHz mu-law) for the whole call.
- **Connect time:** the browser client rang 0.35 to 0.56 s after Twilio hit our webhook, and the stream started 0.8 to
  1.0 s after it, before anyone answered. The caller's phone timer showed the laptop answering 1 to 2 s into the call;
  nothing felt slow on the caller's side. Time spent before Twilio answers (carrier routing, here international) was
  not measured separately.
- **Caveat:** `voiced_bytes` only means "not digital silence". Phone-line noise counts too (call 3's caller leg is 100%),
  so it shows audio flowing, not speech quality. Transcription quality on 8 kHz audio is its own day-1 test.
- Not covered: ringing the Android app (`twilio_voice` and FCM), which is the app lane's test.

## Go / no-go

- **Go (Jaga line as planned):** all 3 calls show both legs with voice, and dial-to-ring is under about 5 s.
- **No-go (browser-dialer fallback):** a leg is missing or silent, or ringing takes over about 10 s. The demo then
  calls the Jaga number from a browser dialer instead of forwarding a SIM.

**Decision: go.** Both legs arrived on all 3 calls and the client rang within 0.6 s of the webhook, so we keep the Jaga
line as planned (ADR 0002). The browser-dialer fallback stays unused unless the Android ring test fails.
