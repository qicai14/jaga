# 014: Family alerts (server)

Lane: A
Status: ready-for-agent
Blocked by: 013

**What to build:** Family co-pilots get pushed at the right moments, and only then.

- [ ] One push the first time a call reaches `isolation` or higher, one more on `money` or `credentials`: at most 2 per call
- [ ] A "may be genuine" follow-up push when Spark lowers a Warning
- [ ] Sent to every linked family co-pilot (up to 3) through the fake push client
- [ ] Summary is at most 200 characters with up to 2 masked quotes; never the transcript
- [ ] A protected user's dismissal doesn't stop pushes
- [ ] All tested at seam 1
