"""The stage tracker: free, deterministic rules from a region pack's phrases and hard triggers (ADR 0005).

Stages come from the caller leg. The user leg only matters when the protected user reads out a TAC,
account number or IC. Rules alone reach a Caution; a hard trigger raises a Warning.
Muse Spark confirms or lowers it.
"""

import json
import os
import re
import unicodedata
from collections import deque
from pathlib import Path

from pydantic import ValidationError

from jaga.spark import Verdict

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
RISK = {"low": 0, "medium": 1, "high": 2}


# A transcriber may space out or punctuate CJK text; none of that is part of a phrase.
CJK_GAP = re.compile(r"(?<=[㐀-鿿])[\s，。、！？；：,.!?;:]+(?=[㐀-鿿])")


def norm(text: str) -> str:
    """Lowercase, full-width folded (NFKC) and with nothing between two CJK characters."""
    return CJK_GAP.sub("", unicodedata.normalize("NFKC", text).lower())


def load_pack(region: str | None) -> dict:
    """The region pack for a protected user's call; an unknown region fails loudly."""
    region = region or os.environ.get("JAGA_DEFAULT_REGION", "")
    path = DIR / f"{region}.json"
    if not re.fullmatch(r"[a-z0-9_-]+", region) or not path.is_file():
        raise ValueError(f"no region pack {region!r}")
    return json.loads(path.read_text(encoding="utf-8"))


def phrase(region: str, phrase_id: str) -> dict:
    """A phrase library entry by its stable ID (Spark picks by ID, #13); unknown fails loudly."""
    for lib in load_pack(region)["library"].values():
        for entry in [lib["command"], *lib["counterMoves"]]:
            if entry["id"] == phrase_id:
                return entry
    raise KeyError(phrase_id)


def official_contact(region: str, agency: str) -> dict:
    """The region pack's static entry for an agency (name, number, purpose, hours, source, checked).

    Valid keys are those in the pack's `contacts` (my.json); the scam hotline 997 is `nsrc`.
    """
    return load_pack(region)["contacts"][agency]


class StageTracker:
    def __init__(self, pack: dict):
        self.pack = pack
        self.disclosure = {label: re.compile(rx) for label, rx in pack["userDisclosure"].items()}
        words = sorted(pack["digitWords"], key=len, reverse=True)
        self.digit_words = re.compile(rf"\b({'|'.join(map(re.escape, words))})\b")
        # Phrases are matched in the same normal form as the transcript.
        self.phrases = {s: [norm(p) for p in ps] for s, ps in pack["phrases"].items()}
        self.hard_triggers = {norm(p): s for p, s in pack["hardTriggers"].items()}
        self.negation = {k: re.compile(rx) for k, rx in pack["negation"].items()}
        self.code_ask, self.bare_tac = re.compile(pack["codeAsk"]), re.compile(pack["bareTac"])
        self.stage, self.risk = "none", "low"
        self.evidence: list[str] = []
        self.counter: str | None = None  # the counter-move text of the Warning on screen
        # Each leg's last two lines, so a phrase or number split across up to three lines matches.
        self.prev: dict[str, deque[str]] = {}
        self.asked = (
            0  # user lines left in which a bare six-digit run counts as a TAC (the caller just asked)
        )

    def digits(self, text: str) -> str:
        """Spoken digits as numerals, joined into one number: 'empat lapan, dua' -> '482'."""
        text = self.digit_words.sub(lambda m: str(self.pack["digitWords"][m[1]]), text)
        return re.sub(r"(?<=\d)[ ,.]+(?=\d)", "", text)

    def mask(self, text: str) -> str:
        """Every run of 4+ digits (IC, account, TAC) masked, spoken or typed."""
        return re.sub(r"\d(?:[ \-–/_.]?\d){3,}", "[number]", self.digits(text))

    def snippet(self) -> str:
        """Each leg's latest lines, for Muse Spark, with every run of 4+ digits (IC, account, TAC) masked,
        spoken or typed."""
        # shortcut: legs are listed one after the other, not in conversation order; fine for a masked hint.
        text = "\n".join(f"{leg}: {' '.join(lines)}" for leg, lines in self.prev.items())
        return self.mask(text)

    def negated(self, window: str, trigger: str) -> bool:
        """True if a bank is warning against the trigger ("never share your TAC"), not asking for it."""
        start = window.find(trigger)
        return bool(
            self.negation["before"].search(window[:start])
            or self.negation["after"].match(window[start + len(trigger) :])
        )

    def hear(self, leg: str, line: str) -> dict | None:
        """The new stage-update fields if this line changed the call's stage or risk, else None."""
        text, hard = norm(line), []
        if leg == "user":
            text = self.digits(text)
        lines = self.prev.setdefault(leg, deque(maxlen=2))
        prev = norm(" ".join(lines))
        window = norm(f"{prev} {text}")
        lines.append(text)
        if leg == "user":
            window = self.digits(window)
        # A match wholly inside the earlier lines already counted.
        if leg == "caller":
            fresh = lambda p: p in window and p not in prev  # noqa: E731
            hits = [(s, p) for s, ps in self.phrases.items() for p in ps if fresh(p)]
            hard = [(s, p) for p, s in self.hard_triggers.items() if fresh(p) and not self.negated(window, p)]
            # shortcut: the ask lasts three user lines, however long they take; fine for a spoken exchange.
            if any(s == "credentials" for s, _ in hard) or self.code_ask.search(text):
                self.asked = 3
        else:
            rxs = dict(self.disclosure)
            if self.asked:
                self.asked -= 1
                rxs["TAC read out"] = self.bare_tac
            # Evidence is the label, never what the user said: it must not echo their digits.
            hits = [
                ("credentials", label)
                for label, rx in rxs.items()
                if rx.search(window) and not rx.search(prev)
            ]
        found = hits + hard
        # max keeps the first of equals: user disclosure ties up to credentials, a caller never flips it back.
        seen = [s for s, _ in found]
        stage = max(seen + [self.stage] if leg == "user" else [self.stage] + seen, key=RANK.__getitem__)
        if stage == self.stage and not hard:
            return None
        # Rules alone stay at a Caution unless a hard trigger fired or a Warning already stands (ADR 0005).
        risk = "high" if hard or self.risk == "high" else "medium" if stage != "none" else "low"
        if (stage, risk) == (self.stage, self.risk):
            return None
        self.stage, self.risk = stage, risk
        self.evidence = list(dict.fromkeys(p for _, p in found))[:3]
        return self.show()

    def show(self, counter: dict | None = None) -> dict:
        """The stage-update fields for the current state, remembered as what's on screen.

        A Warning has library text only (ADR 0006)."""
        fields = {"stage": self.stage, "risk": self.risk, "evidence": self.evidence}
        self.counter = None
        if self.risk == "high":
            lang, lib = self.pack["defaultLanguage"], self.pack["library"][self.stage]
            self.counter = (counter or lib["counterMoves"][0])["text"][lang]
            fields |= {"command": lib["command"]["text"][lang], "counterMove": self.counter}
        return fields

    def spark_said(self, raw: dict | None) -> dict | None:
        """The stage-update fields once Muse Spark has answered, or None if nothing changes.

        `raw` is Spark's unchecked output; None, invalid output and a counter-move not of this stage all count
        as Spark failing, when a call at money or credentials still gets a Warning (spec fail-safe).
        """
        try:
            verdict = Verdict.model_validate(raw)
            # Only this stage's counter-moves: a command or another stage's ID is invalid output.
            moves = {m["id"]: m for m in self.pack["library"][self.stage]["counterMoves"]}
            counter = moves[verdict.counterMove]
        except (ValidationError, KeyError):
            if RANK[self.stage] < RANK["money"] or self.risk == "high":
                return None
            self.risk = "high"
            return self.show()
        before = self.risk, self.counter
        # A Warning can be lowered to a Caution but not to low. The stage comes from the rules alone.
        floor = "medium" if self.risk == "high" else "low"
        self.risk = max(verdict.risk, floor, key=RISK.__getitem__)
        fields = self.show(counter)
        return fields | {"source": "spark"} if before != (self.risk, self.counter) else None
