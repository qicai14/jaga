"""Seam 1: a scripted call goes into the Twilio Media Streams WebSocket, `stage-update` messages come out."""

import asyncio
import json
import time
from pathlib import Path
from xml.etree import ElementTree

import pytest
from fastapi.testclient import TestClient
from jsonschema import Draft202012Validator
from starlette.websockets import WebSocketDisconnect

from jaga import asr, stages, telephony, twilio_auth
from jaga.fakes.transcribe import FakeTranscriber
from jaga.fakes.twilio import media_stream
from jaga.main import app

CONTRACTS = Path(__file__).resolve().parents[2] / "contracts"
STAGE_UPDATE = Draft202012Validator(
    json.loads((CONTRACTS / "stage-update.schema.json").read_text(encoding="utf-8")),
    format_checker=Draft202012Validator.FORMAT_CHECKER,
)

TOKEN = "test-auth-token"
# What Twilio signs: the public https URL, and wss for the stream.


def media_headers():
    return {"X-Twilio-Signature": twilio_auth.signature("wss://testserver/twilio/media", {}, TOKEN)}


SCRIPT = [
    ("caller", "Hello, saya dari Pos Malaysia. Ada bungkusan untuk puan."),
    ("user", "Bungkusan apa?"),
    ("caller", "Bungkusan dari Shopee, boleh sahkan alamat?"),
]


@pytest.fixture
def heard(monkeypatch):
    """Every (leg, line) the fake transcriber produced."""
    lines, transcribe = [], FakeTranscriber.transcribe

    async def record(self, leg, audio):
        line = await transcribe(self, leg, audio)
        lines.append((leg, line))
        return line

    monkeypatch.setattr(FakeTranscriber, "transcribe", record)
    return lines


@pytest.fixture
def client(monkeypatch):
    monkeypatch.setenv("JAGA_USE_FAKES", "true")
    monkeypatch.setenv("JAGA_DEFAULT_REGION", "my")
    monkeypatch.setenv("TWILIO_AUTH_TOKEN", TOKEN)
    # One TestClient context shares one event loop between the call's WebSocket and the app's stage stream.
    with TestClient(app) as client:
        yield client


def follow(app_stream):
    """Everything the app receives until the stage stream closes."""
    received = []
    with pytest.raises(WebSocketDisconnect):
        while True:
            received.append(app_stream.receive_json())
    return received


def wait_for_start(call_sid):
    deadline = time.monotonic() + 5
    while call_sid not in telephony.calls:
        assert time.monotonic() < deadline, "the call never started"
        time.sleep(0.01)


def play_call(client, call_sid, script, before_end=(), region=None):
    """Plays the call; the app joins its stage stream once the call starts. Returns what the app got."""
    start, *media, stop = media_stream(call_sid, script, region)[1:]
    with client.websocket_connect("/twilio/media", headers=media_headers()) as twilio:
        twilio.send_text(start)
        wait_for_start(call_sid)
        with client.websocket_connect(f"/calls/{call_sid}/stages") as app_stream:
            for msg in [*media, *before_end, stop]:
                twilio.send_text(msg)
            return follow(app_stream)


def test_scripted_call_comes_out_as_stage_updates(client, heard):
    updates = play_call(client, "CA_fake_1", SCRIPT)

    assert heard == SCRIPT
    assert updates, "the app got no stage-update"
    for update in updates:
        STAGE_UPDATE.validate(update)
        assert update["callId"] == "CA_fake_1"
        assert (update["stage"], update["risk"]) == ("none", "low")


def trail(client, call_sid, script, region=None):
    """The schema-valid updates of a scripted call."""
    updates = play_call(client, call_sid, script, region=region)
    for update in updates:
        STAGE_UPDATE.validate(update)
    return updates


def stages_of(updates):
    return [(u["stage"], u["risk"]) for u in updates]


def test_caller_script_climbs_the_stages_and_rules_stop_at_caution(client):
    updates = trail(
        client,
        "CA_climb",
        [
            ("caller", "Ada bungkusan haram atas nama puan."),
            ("caller", "Saya Inspektor Ali dari PDRM."),
            ("caller", "Ada waran tangkap untuk puan."),
        ],
    )

    assert stages_of(updates) == [
        ("none", "low"),
        ("pretext", "medium"),
        ("authority", "medium"),
        ("fear", "medium"),
    ]
    assert {u["source"] for u in updates} == {"rules"}
    assert all(u["command"] is None and u["counterMove"] is None for u in updates)


def test_stage_never_goes_down(client):
    updates = trail(
        client,
        "CA_down",
        [
            ("caller", "Ada waran tangkap untuk puan."),
            ("caller", "Saya dari PDRM."),
            ("caller", "Ada bungkusan haram."),
        ],
    )

    assert stages_of(updates) == [("none", "low"), ("fear", "medium")]


def test_hard_trigger_is_a_warning_at_once_and_rules_never_lower_it(client):
    updates = trail(
        client,
        "CA_hard",
        [
            ("caller", "Ada bungkusan haram atas nama puan."),
            ("caller", "Jangan beritahu sesiapa ya."),
            ("caller", "Saya dari PDRM."),
        ],
    )

    assert stages_of(updates) == [("none", "low"), ("pretext", "medium"), ("isolation", "high")]
    warning = updates[-1]
    assert warning["source"] == "rules"
    assert warning["command"] and warning["counterMove"]
    assert warning["evidence"] == ["jangan beritahu sesiapa"]


@pytest.mark.parametrize(
    "said", ["Kod saya 482913.", "Nombor akaun 1234567890123.", "IC saya 900101-14-5678."]
)
def test_protected_user_reading_out_credentials_moves_the_call_to_credentials(client, said):
    updates = trail(client, "CA_user", [("caller", "Saya dari PDRM."), ("user", said)])

    assert stages_of(updates)[-1] == ("credentials", "high")
    assert not any(c.isdigit() for e in updates[-1]["evidence"] for c in e)


def test_the_same_digits_from_the_caller_do_not(client):
    updates = trail(
        client, "CA_caller_digits", [("caller", "Kod 482913, akaun 1234567890123, IC 900101-14-5678.")]
    )

    assert stages_of(updates) == [("none", "low")]


def test_region_comes_from_the_call_or_the_default(client, monkeypatch, tmp_path):
    for region, phrase in {"alpha": "kucing oren", "beta": "anjing hitam"}.items():
        pack = {
            "command": "c",
            "counterMove": "m",
            "hardTriggers": {},
            "userDisclosure": {},
            "digitWords": {"nol": 0},
        }
        (tmp_path / f"{region}.json").write_text(json.dumps(pack | {"phrases": {"pretext": [phrase]}}))
    monkeypatch.setattr(stages, "DIR", tmp_path)
    monkeypatch.setenv("JAGA_DEFAULT_REGION", "beta")
    script = [("caller", "kucing oren")]

    assert stages_of(trail(client, "CA_alpha", script, region="alpha"))[-1] == ("pretext", "medium")
    assert stages_of(trail(client, "CA_default", script)) == [("none", "low")]


def test_second_start_keeps_the_call_so_the_app_still_sees_the_end(client):
    start = media_stream("CA_dup", [])[1]
    assert len(play_call(client, "CA_dup", SCRIPT, before_end=[start])) == 1


def test_malformed_message_ends_the_call(client):
    assert len(play_call(client, "CA_bad", [], before_end=["not json"])) == 1


def test_stage_stream_for_unknown_call_is_refused(client):
    with pytest.raises(WebSocketDisconnect), client.websocket_connect("/calls/CA_unknown/stages"):
        pass


@pytest.mark.parametrize(
    "line",
    [
        "This is the bank, your card statement is ready, we will never ask for your password, "
        "let me transfer you to a colleague.",
        "Ini LHDN, peringatan bayaran cukai melalui portal rasmi.",
    ],
)
def test_genuine_bank_and_tax_calls_stay_at_none(client, line):
    assert stages_of(trail(client, "CA_genuine", [("caller", line)])) == [("none", "low")]


def test_a_phone_number_from_the_user_is_not_an_account_number(client):
    updates = trail(client, "CA_phone", [("user", "Telefon saya 0123456789.")])

    assert stages_of(updates) == [("none", "low")]


def test_user_disclosure_ties_with_money_but_the_caller_never_takes_credentials_back(client):
    updates = trail(
        client,
        "CA_tie",
        [
            ("caller", "Pindahkan wang sekarang."),
            ("user", "Kod saya 482913."),
            ("caller", "Pindahkan wang lagi."),
        ],
    )

    assert stages_of(updates) == [("none", "low"), ("money", "high"), ("credentials", "high")]


def test_money_or_credentials_is_a_warning_while_spark_is_missing(client):
    updates = trail(client, "CA_failsafe", [("caller", "Bayar jaminan hari ini.")])

    assert stages_of(updates) == [("none", "low"), ("money", "high")]
    assert updates[-1]["source"] == "rules"
    assert updates[-1]["command"] and updates[-1]["counterMove"]


def test_unknown_region_closes_the_stream_and_logs_it(client, caplog):
    start = media_stream("CA_zz", [], region="zz")[1]
    with client.websocket_connect("/twilio/media", headers=media_headers()) as twilio:
        twilio.send_text(start)
        with pytest.raises(WebSocketDisconnect):
            twilio.receive_text()

    assert "CA_zz" not in telephony.calls
    assert "'zz'" in caplog.text


def voice(client, signed_with=TOKEN, **params):
    form = {"CallSid": ["CA_v"], "From": ["+60123456789"]} | params
    sig = twilio_auth.signature("https://testserver/twilio/voice", form, signed_with)
    body = "&".join(f"{k}={v[0]}".replace("+", "%2B") for k, v in form.items())
    return client.post(
        "/twilio/voice",
        content=body,
        headers={"X-Twilio-Signature": sig, "Content-Type": "application/x-www-form-urlencoded"},
    )


def test_voice_webhook_streams_both_tracks_with_the_region_and_rings_the_app(client, monkeypatch):
    monkeypatch.setenv("JAGA_APP_CLIENT_IDENTITY", "jaga-app")
    response = voice(client)

    assert response.status_code == 200
    twiml = ElementTree.fromstring(response.text)
    stream = twiml.find("Start/Stream")
    assert stream.get("url") == "wss://testserver/twilio/media"
    assert stream.get("track") == "both_tracks"
    assert {p.get("name"): p.get("value") for p in stream.findall("Parameter")} == {"region": "my"}
    assert twiml.findtext("Dial/Client") == "jaga-app"


def test_voice_webhook_without_a_valid_signature_is_refused(client):
    assert voice(client, signed_with="someone-elses-token").status_code == 403
    assert client.post("/twilio/voice", content="CallSid=CA_v").status_code == 403


def test_media_stream_without_a_valid_signature_is_refused(client):
    for headers in ({}, {"X-Twilio-Signature": "forged"}):
        with pytest.raises(WebSocketDisconnect), client.websocket_connect("/twilio/media", headers=headers):
            pass


def test_signature_matches_twilios_documented_example():
    params = {
        "CallSid": ["CA1234567890ABCDE"],
        "Caller": ["+12349013030"],
        "Digits": ["1234"],
        "From": ["+12349013030"],
        "To": ["+18005551212"],
    }
    url = "https://mycompany.com/myapp.php?foo=1&bar=2"

    assert twilio_auth.signature(url, params, "12345") == "0/KCTR6DLpKmkAf8muzZqo1nDgQ="
    assert twilio_auth.valid(url, params, "0/KCTR6DLpKmkAf8muzZqo1nDgQ=", "12345")
    assert not twilio_auth.valid(url, params, "0/KCTR6DLpKmkAf8muzZqo1nDgQ=", "")


def test_a_slow_leg_does_not_hold_up_the_other_and_every_line_still_lands(client, monkeypatch):
    done, transcribe = [], FakeTranscriber.transcribe

    async def slow_caller(self, leg, audio):
        if leg == "caller":
            await asyncio.sleep(0.2)
        line = await transcribe(self, leg, audio)
        done.append((leg, line))
        return line

    monkeypatch.setattr(FakeTranscriber, "transcribe", slow_caller)
    script = [("caller", "Ada bungkusan haram."), ("user", "Hmm."), ("caller", "Ada waran tangkap.")]

    updates = trail(client, "CA_slow", script)

    assert done[0] == ("user", "Hmm.")
    assert [line for leg, line in done if leg == "caller"] == [s[1] for s in script if s[0] == "caller"]
    assert stages_of(updates)[-1] == ("fear", "medium"), "stop must wait for the queued lines"


def test_a_phrase_split_across_two_transcript_lines_still_matches_and_fires_once(client):
    updates = trail(
        client,
        "CA_split",
        [
            ("caller", "Puan, ada bungkusan"),
            ("caller", "haram atas nama puan."),
            ("caller", "Sila dengar baik-baik."),
        ],
    )

    assert stages_of(updates) == [("none", "low"), ("pretext", "medium")]
    assert updates[-1]["evidence"] == ["bungkusan haram"]


@pytest.mark.parametrize(
    "lines",
    [
        ["Kod TAC saya empat lapan dua sembilan satu tiga."],
        ["Kod saya empat lapan dua", "sembilan satu tiga"],
        ["Kod saya zero four eight two nine one"],
        ["Kod saya 4 8 2 sembilan satu 3"],
        ["Kod saya 482 913"],
    ],
)
def test_a_tac_read_out_in_spoken_digits_is_caught(client, lines):
    updates = trail(client, "CA_tac", [("user", line) for line in lines])

    assert stages_of(updates)[-1] == ("credentials", "high")


@pytest.mark.parametrize(
    "said",
    [
        "Akaun saya kosong satu dua tiga empat lima enam tujuh lapan sembilan",
        "Nombor akaun saya 123 456 789 012",
    ],
)
def test_an_account_number_read_out_in_spoken_digits_is_caught(client, said):
    assert stages_of(trail(client, "CA_acct", [("user", said)]))[-1] == ("credentials", "high")


def test_an_ic_read_out_in_spoken_digits_is_caught(client):
    said = "sembilan kosong kosong satu kosong satu, satu empat, lima enam tujuh lapan"
    assert stages_of(trail(client, "CA_ic", [("user", said)]))[-1] == ("credentials", "high")


@pytest.mark.parametrize(
    "said",
    [
        "Hari ini lima sepuluh dua ribu dua puluh lima",
        "Tarikh bungkusan 5 10 2025, jam sepuluh",
        "Nombor tracking bungkusan saya 123456",
        "Nombor tracking saya satu dua tiga empat lima enam",
        "Tracking number MY 4829 1357 9024",
    ],
)
def test_a_date_or_parcel_number_read_out_is_not_a_tac(client, said):
    assert stages_of(trail(client, "CA_date", [("user", said)])) == [("none", "low")]


class MuseSocket:
    """Stands in for the Muse Voice Transcribe realtime socket: a final transcript for each audio frame."""

    def __init__(self, replies):
        self.sent, self.replies, self.inbox = [], list(replies), asyncio.Queue()

    async def send(self, data):
        self.sent.append(data)
        await asyncio.sleep(0)
        if isinstance(data, bytes) and self.replies:
            reply = {"type": "transcript", "transcript": self.replies.pop(0), "final": True}
            self.inbox.put_nowait(json.dumps(reply))

    def __aiter__(self):
        return self

    async def __anext__(self):
        if (item := await self.inbox.get()) is None:
            raise StopAsyncIteration
        return item

    async def close(self):
        self.inbox.put_nowait(None)
        self.closed = True


def test_real_muse_transcribe_gets_16khz_audio_and_the_region_packs_hints(client, monkeypatch, caplog):
    sock, urls = MuseSocket(["Ada bungkusan", "haram atas nama puan."]), []

    async def connect(url):
        urls.append(url)
        return sock

    monkeypatch.setenv("JAGA_USE_FAKES", "false")
    monkeypatch.setenv("META_API_KEY", "muse-key")
    monkeypatch.setenv("META_API_BASE_URL", "https://api.meta.ai/v1")
    monkeypatch.setattr(asr, "connect", connect)
    caplog.set_level("DEBUG")
    # The bytes only need a length: each mu-law byte becomes two 16 kHz samples of two bytes.
    chunks = [("caller", "x" * 160)] * 4

    updates = trail(client, "CA_muse", chunks)

    assert urls == ["wss://api.meta.ai/v1/asr/realtime"]
    handshake = json.loads(sock.sent[0])
    assert handshake["authorization"] == {"accessToken": "Bearer muse-key"}
    assert (handshake["audioEncoding"], handshake["mode"]) == ("PCM_16KHZ", "ENDPOINTING")
    assert handshake["languageBias"] == ["Malay", "English", "Mandarin Chinese", "Tamil"]
    assert {"LHDN", "akaun selamat", "TAC", "997"} <= set(handshake["keywords"])
    assert [len(frame) for frame in sock.sent[1:]] == [640] * 4
    assert stages_of(updates)[-1] == ("pretext", "medium")
    assert sock.closed
    assert "bungkusan" not in caplog.text and "muse-key" not in caplog.text
