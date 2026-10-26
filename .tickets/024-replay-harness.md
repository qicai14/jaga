# 024: Replay harness

Lane: C
Status: ready-for-agent
Blocked by: 005, 020

**What to build:** Recorded calls go through the real pipeline exactly as live calls do.

- [ ] Recorded audio streamed at real-time speed through seam 1 with real APIs
- [ ] Also runs with the fake transcriber for cheap runs
- [ ] Records every `stage-update`, family alert and timing per call
