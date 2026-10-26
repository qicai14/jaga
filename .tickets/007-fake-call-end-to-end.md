# 007: Fake call end to end

Lane: A
Status: ready-for-agent
Blocked by: 001

**What to build:** Tracer bullet: a scripted call played into the server comes out as `stage-update` messages, with every external client faked. This creates seam 1.

- [ ] Under `JAGA_USE_FAKES=true`, a test plays a scripted two-leg call into the Twilio Media Streams WebSocket
- [ ] The fake transcriber turns each audio chunk into a scripted line, so tests read like call scripts
- [ ] The app's stage stream receives `stage-update` messages (stage `none`, risk low) that validate against the contract
- [ ] The call has a `callId` and a clear start and end
