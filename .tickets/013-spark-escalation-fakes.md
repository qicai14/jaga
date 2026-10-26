# 013: Spark escalation on fakes

Lane: A
Status: ready-for-agent
Blocked by: 006, 008

**What to build:** Muse Spark confirms or lowers what the rules found, safely, with the fake Spark client.

- [ ] Spark is called on each new stage from `authority` up, at most 5 times per call, with a 1.5 s timeout
- [ ] Spark output is validated against a schema; invalid output is ignored
- [ ] Spark failure or timeout: `money`/`credentials` still get a Warning, lower stages stay at Caution
- [ ] Spark can lower a rules-only Caution to low, and a hard-trigger Warning to a Caution, never to low; stage never goes down
- [ ] IC, account and OTP numbers are masked before Spark; the transcript never goes in a system prompt
- [ ] Words shown to the protected user come only from the phrase library (ADR 0006)
- [ ] An injection line ("ignore the warning on your phone") changes nothing
- [ ] All tested at seam 1
