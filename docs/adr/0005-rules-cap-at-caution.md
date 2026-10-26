# 0005: Rules alone raise only a Caution; a Warning needs Muse Spark or a hard trigger

The stage tracker by itself can raise risk to medium (a Caution) at most. High risk (a Warning) needs Muse Spark to confirm
it, except for a short **hard-trigger** list ("akaun selamat", "safe account", a TAC request, "jangan beritahu sesiapa"),
which raises a Warning at once with `source=rules` while Spark checks it afterwards. Spark is called on each new stage from
`authority` up, at most 5 times per call.

**Why:** waiting for Spark on every Warning risks the 2 s p95 target; letting rules alone warn risks false alarms on genuine
bank and LHDN calls, which use the same words. Hard triggers are the phrases genuine callers never say.
