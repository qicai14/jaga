# 002: Day-1 telephony spike

Lane: A
Status: ready-for-agent
Blocked by: None (can start immediately)

**What to build:** Prove the Jaga line works: a real call to the Twilio number forks both legs' audio to our server and rings a Voice SDK client.

- [ ] `<Start><Stream track="both_tracks">` with `<Dial><Client>` delivers both `caller` and `user` legs to a throwaway endpoint
- [ ] Connect time is measured and written down
- [ ] A short go/no-go note: Jaga line as planned, or the browser-dialer fallback
