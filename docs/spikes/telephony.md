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

## Results

| Call | Dial to ring (stopwatch) | `incoming_s` | `accepted_s` | caller frames / voiced | user frames / voiced |
|------|--------------------------|--------------|--------------|------------------------|----------------------|
| 1    |                          |              |              |                        |                      |
| 2    |                          |              |              |                        |                      |
| 3    |                          |              |              |                        |                      |

## Go / no-go

- **Go (Jaga line as planned):** all 3 calls show both legs with voice, and dial-to-ring is under about 5 s.
- **No-go (browser-dialer fallback):** a leg is missing or silent, or ringing takes over about 10 s. The demo then
  calls the Jaga number from a browser dialer instead of forwarding a SIM.

**Decision:** _pending the calls above._
