import json

from jaga.stages import RANK


class FakeSpark:
    """Confirms what the rules found, and a Warning from money up, with the stage's first counter-move.
    Tests script other answers by replacing `assess`."""

    def __init__(self, pack: dict):
        self.pack = pack

    async def assess(self, stage: str, risk: str, snippet: str) -> dict:
        risk = "high" if RANK[stage] >= RANK["money"] else risk
        return {
            "stage": stage,
            "risk": risk,
            "counterMove": self.pack["library"][stage]["counterMoves"][0]["id"],
        }

    async def generate(self, rules: str, prompt: str, schema: dict, timeout: float = 60) -> tuple[str, dict]:
        lines = [{"speaker": "caller", "text": "Hello, this is a test call.", "stage": "none"}]
        return json.dumps({"lines": lines}), {"input_tokens": 10, "output_tokens": 20}
