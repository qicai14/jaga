# 008: Stage tracker with the Malaysia region pack

Lane: A
Status: ready-for-agent
Blocked by: 007

**What to build:** The free rule layer recognises the Macau scam script and raises a Caution, or a Warning on a hard trigger, with no model call.

- [ ] The region pack loads per protected user; no code hard-codes a country
- [ ] A call's stage is the most severe seen so far and never goes down
- [ ] Rules alone raise risk to medium (Caution) at most
- [ ] A hard trigger raises a Warning at once with `source=rules`
- [ ] Stages come from the caller leg; the protected user reading out a TAC, account number or IC moves the call to `credentials`
- [ ] A genuine-call script stays at `none`
- [ ] All tested at seam 1
