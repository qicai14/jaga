# 015: Jaga Pause API

Lane: D
Status: ready-for-agent
Blocked by: 001, 008

**What to build:** A bank can ask whether a customer is mid-scam and how long to hold.

- [ ] The bank asks with a pause token
- [ ] `inScam` is true while a call is live at `isolation` or higher, and for 30 minutes after it ends
- [ ] `recommendedHoldMinutes` is 30 at `money`/`credentials`, 15 at `isolation`/`handoff`, 0 otherwise
- [ ] Only a family co-pilot can clear it early; the protected user's dismissal never does
- [ ] Answers validate against the `pause` contract; tested at seam 1
