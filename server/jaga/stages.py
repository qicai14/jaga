"""The stage tracker: free, deterministic rules from a region pack's phrases and hard triggers (ADR 0005).

Stages come from the caller leg. The user leg only matters when the protected user reads out a TAC,
account number or IC. Rules alone reach a Caution; a hard trigger or money/credentials raises a Warning.
"""

import json
import os
import re
from pathlib import Path

DIR = Path(__file__).parent / "regions"
# money and credentials tie as most severe (GLOSSARY).
RANK = {
    "none": 0,
    "pretext": 1,
    "authority": 2,
    "fear": 3,
    "isolation": 4,
    "handoff": 5,
    "money": 6,
    "credentials": 6,
}


def load_pack(region: str | None) -> dict:
    """The region pack for a protected user's call; an unknown region fails loudly."""
    region = region or os.environ.get("JAGA_DEFAULT_REGION", "")
    path = DIR / f"{region}.json"
    if not re.fullmatch(r"[a-z0-9_-]+", region) or not path.is_file():
        raise ValueError(f"no region pack {region!r}")
    return json.loads(path.read_text(encoding="utf-8"))


class StageTracker:
    def __init__(self, pack: dict):
        self.pack = pack
        self.disclosure = {label: re.compile(rx) for label, rx in pack["userDisclosure"].items()}
        words = sorted(pack["digitWords"], key=len, reverse=True)
        self.digit_words = re.compile(rf"\b({'|'.join(map(re.escape, words))})\b")
        self.stage, self.risk = "none", "low"
        self.prev: dict[str, str] = {}  # each leg's previous line, so a phrase split across two lines matches

    def digits(self, text: str) -> str:
        """Spoken digits as numerals, joined into one number: 'empat lapan, dua' -> '482'."""
        text = self.digit_words.sub(lambda m: str(self.pack["digitWords"][m[1]]), text)
        return re.sub(r"(?<=\d)[ ,.]+(?=\d)", "", text)

    def hear(self, leg: str, line: str) -> dict | None:
        """The new stage-update fields if this line changed the call's stage or risk, else None."""
        text, hard = line.lower(), []
        if leg == "user":
            text = self.digits(text)
        prev, self.prev[leg] = self.prev.get(leg, ""), text
        window = f"{prev} {text}"
        if leg == "user":
            window = self.digits(window)
        # A match wholly inside the previous line already counted.
        if leg == "caller":
            fresh = lambda p: p in window and p not in prev  # noqa: E731
            hits = [(s, p) for s, ps in self.pack["phrases"].items() for p in ps if fresh(p)]
            hard = [(s, p) for p, s in self.pack["hardTriggers"].items() if fresh(p)]
        else:
            # Evidence is the label, never what the user said: it must not echo their digits.
            hits = [
                ("credentials", label)
                for label, rx in self.disclosure.items()
                if rx.search(window) and not rx.search(prev)
            ]
        found = hits + hard
        # max keeps the first of equals: user disclosure ties up to credentials, a caller never flips it back.
        seen = [s for s, _ in found]
        stage = max(seen + [self.stage] if leg == "user" else [self.stage] + seen, key=RANK.__getitem__)
        # shortcut: no Spark yet counts as Spark failing, so the spec's fail-safe Warning at money/credentials
        # applies now; #13 moves it behind the real Spark call and its timeout.
        warn = hard or self.risk == "high" or RANK[stage] == RANK["money"]
        risk = "high" if warn else "medium" if stage != "none" else "low"
        if (stage, risk) == (self.stage, self.risk):
            return None
        self.stage, self.risk = stage, risk
        evidence = list(dict.fromkeys(p for _, p in found))[:3]
        fields = {"stage": stage, "risk": risk, "evidence": evidence}
        if risk == "high":
            fields |= {"command": self.pack["command"], "counterMove": self.pack["counterMove"]}
        return fields
