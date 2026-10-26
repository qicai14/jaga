# 025: Metrics report and ablation

Lane: C
Status: ready-for-agent
Blocked by: 018, 021, 024

**What to build:** The evidence table judges will read, against the targets fixed in the plan.

- [ ] Caught before `money`, false alarms per 10 hours of genuine calls (Cautions reported separately), p50/p95 time to Warning, cost per call, transcription error rate
- [ ] Spark failures and timeouts counted
- [ ] Ablation: rules only vs rules plus Spark vs Spark only
- [ ] Bootstrap confidence intervals; misses reported honestly; never tuned on the held-out set
