class FakePush:
    """Records every alert it is asked to send; tests read `sent`."""

    def __init__(self):
        self.sent: list[tuple[str, dict]] = []

    async def send(self, token: str, alert: dict) -> None:
        self.sent.append((token, alert))
