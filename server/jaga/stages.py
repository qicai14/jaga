"""The stage tracker: free, deterministic rules from a region pack's script pack (ADR 0005).

Stages come from the caller leg. The user leg only matters when the protected user reads out a TAC,
account number or IC. Rules alone reach a Caution; only a hard trigger raises a Warning.
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
    if not re.fullmatch(r"[a-z0-9_-]+", region) or not (DIR / f"{region}.json").is_file():
        raise ValueError(f"no region pack {region!r}")
    return json.loads((DIR / f"{region}.json").read_text(encoding="utf-8"))


class StageTracker:
    def __init__(self, pack: dict):
        self.pack = pack
        self.disclosure = {label: re.compile(rx) for label, rx in pack["userDisclosure"].items()}
        self.stage, self.risk = "none", "low"

    def hear(self, leg: str, line: str) -> dict | None:
        """The new stage-update fields if this line changed the call's stage or risk, else None."""
        text, hard = line.lower(), []
        if leg == "caller":
            hits = [(s, p) for s, ps in self.pack["phrases"].items() for p in ps if p in text]
            hard = [(s, p) for p, s in self.pack["hardTriggers"].items() if p in text]
        else:
            # Evidence is the label, never what the user said: it must not echo their digits.
            hits = [("credentials", label) for label, rx in self.disclosure.items() if rx.search(text)]
        stage = max([self.stage] + [s for s, _ in hits + hard], key=RANK.__getitem__)
        risk = "high" if hard or self.risk == "high" else "medium" if stage != "none" else "low"
        if (stage, risk) == (self.stage, self.risk):
            return None
        self.stage, self.risk = stage, risk
        evidence = list(dict.fromkeys(p for _, p in hits + hard))[:3]
        fields = {"stage": stage, "risk": risk, "evidence": evidence}
        if risk == "high":
            fields |= {"command": self.pack["command"], "counterMove": self.pack["counterMove"]}
        return fields
