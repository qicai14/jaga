# 001: Contracts v1

Lane: A
Status: ready-for-agent
Blocked by: None (can start immediately)

**What to build:** The three draft contracts become v1 and match the spec, so server and app can build against them in parallel.

- [ ] `pause` has a request shape carrying the pause token
- [ ] `stage-update` allows `command` and `counterMove` only when risk is high, and the counter-move phrase-ID vs resolved-text choice is made
- [ ] `family-alert` has a kind for the "may be genuine" follow-up
- [ ] A new stage-timeline contract (stages, times, risk changes, `source`, masked evidence)
- [ ] ADR 0007 records the v1 contracts, in its own PR with no feature code
- [ ] Example fixtures for every contract, and a test that validates each fixture against its schema
