"""The phrase library and official contacts in the Malaysia region pack (#6)."""

from datetime import date

import pytest

from jaga.stages import RANK, StageTracker, load_pack, official_contact, phrase

STAGES = [s for s in RANK if s != "none"]
LANGS = ["ms", "en", "zh"]


def entries(pack):
    for stage in STAGES:
        lib = pack["library"][stage]
        yield stage, lib["command"], True
        for move in lib["counterMoves"]:
            yield stage, move, False


def test_every_stage_has_a_command_and_counter_move_in_three_languages():
    pack = load_pack("my")
    assert set(pack["library"]) == set(STAGES)
    for stage in STAGES:
        assert pack["library"][stage]["counterMoves"]
    for _, entry, _ in entries(pack):
        assert entry["id"]
        assert set(entry["text"]) == set(LANGS)
        assert all(entry["text"][lang].strip() for lang in LANGS)


def test_phrase_ids_are_unique_and_look_up_to_their_entry():
    pack = load_pack("my")
    ids = [e["id"] for _, e, _ in entries(pack)]
    assert len(ids) == len(set(ids))
    assert phrase("my", "my.fear.command")["text"]["en"]
    with pytest.raises(KeyError):
        phrase("my", "my.nope")


def test_the_command_is_followed_by_english_in_every_language():
    pack = load_pack("my")
    for _, entry, is_command in entries(pack):
        if is_command:
            en = entry["text"]["en"]
            assert all(entry["text"][lang].endswith(f" {en}") for lang in ("ms", "zh"))


def test_machine_drafted_languages_are_marked_for_native_review():
    review = load_pack("my")["libraryReview"]
    assert all(review[lang].strip() for lang in ("ms", "zh"))
    assert "en" not in review


def test_official_contact_returns_the_number_with_its_source():
    nsrc = official_contact("my", "nsrc")
    assert nsrc["number"] == "997"
    assert official_contact("my", "pdrm")["number"] == "999"
    for agency in ["pdrm", "lhdn", "bnm", "maybank", "cimb", "public_bank", "rhb"]:
        assert official_contact("my", agency)["number"]


def test_every_contact_has_a_number_a_source_and_a_checked_date():
    contacts = load_pack("my")["contacts"]
    for agency in ["nsrc", "pdrm", "lhdn", "bnm", "maybank", "cimb", "public_bank", "rhb"]:
        assert agency in contacts
    for agency, c in contacts.items():
        assert c["number"] and c["name"] and c["purpose"] and c["hours"], agency
        assert c["source"].startswith("https://"), agency
        date.fromisoformat(c["checked"])


def test_unknown_agency_or_region_fails_loudly():
    with pytest.raises(KeyError):
        official_contact("my", "ccid")
    with pytest.raises(ValueError):
        official_contact("xx", "nsrc")


def stage_after(*lines):
    tracker = StageTracker(load_pack("my"))
    for line in lines:
        tracker.hear("caller", line)
    return tracker.stage, tracker.risk


@pytest.mark.parametrize(
    "line",
    [
        "Hello encik, saya dari syarikat kurier, ada satu bungkusan untuk encik.",
        "Eh, parcel atas nama you tersangkut kat pejabat, boleh cakap sekejap?",
        "Puan, ada tunggakan cukai yang belum dijelaskan.",
        "I'm calling from Bank Negara about your account.",
        "You were added to a WhatsApp investment group last week.",
        "There is a parcel under your name and it has unpaid tax.",
    ],
)
def test_pretext_phrases_in_malay_manglish_and_english_raise_a_caution(line):
    assert stage_after(line) == ("pretext", "medium")


@pytest.mark.parametrize(
    "line",
    [
        "Selamat petang, saya dari unit jenayah komersial, ada kes atas nama puan.",
        "Saya pegawai penyiasat dari Bukit Aman, kita bercakap sekejap ya.",
        "Hello, I'm calling from PDRM regarding your file.",
    ],
)
def test_authority_phrases_in_malay_and_english_raise_a_caution(line):
    assert stage_after(line) == ("authority", "medium")


@pytest.mark.parametrize(
    "line",
    [
        "Kalau tak settle hari ini, polis akan datang ke rumah puan.",
        "Encik akan ditahan dan boleh masuk penjara kalau tak bekerjasama.",
        "Lepas ni kami keluarkan waran dan polis datang tangkap you.",
        "If you refuse, you will be arrested and may go to jail.",
        "Your account will be frozen by tonight.",
    ],
)
def test_fear_phrases_in_malay_manglish_and_english_raise_a_caution(line):
    assert stage_after(line) == ("fear", "medium")


@pytest.mark.parametrize(
    "line",
    [
        "Ini kes sulit ya encik, jangan letak dulu.",
        "Eh, jangan bagitau sesiapa pasal ni, termasuk keluarga.",
        "Please do not tell anyone, even your family.",
    ],
)
def test_isolation_phrases_in_malay_manglish_and_english_raise_a_caution(line):
    assert stage_after(line) == ("isolation", "medium")


@pytest.mark.parametrize(
    "line",
    [
        "Sekejap ya, saya sambungkan tuan kepada pegawai polis yang uruskan kes ini.",
        "Okay, sekarang saya handoff you kepada tuan inspektor, dia akan guide you.",
        "Saya sambungkan puan kepada pegawai atasan kami.",
        "Hold on, I will handoff you to the senior inspector now.",
        "I am handing over your case to the officer in charge.",
    ],
)
def test_handoff_phrases_in_malay_manglish_and_english_raise_a_caution(line):
    assert stage_after(line) == ("handoff", "medium")


@pytest.mark.parametrize(
    "line",
    [
        "Tuan perlu pindahkan semua baki untuk tujuan audit sementara.",
        "Eh, you kena pindahkan semua duit tu hari ini juga.",
        "Puan, semua wang ke akaun yang saya bagi ya.",
        "You must move all your savings before midnight.",
        "Please transfer all your money to the account I give you.",
    ],
)
def test_money_phrases_in_malay_manglish_and_english_raise_a_caution(line):
    assert stage_after(line) == ("money", "medium")


@pytest.mark.parametrize(
    "line",
    [
        "Cepat lah, baca kod tu kat saya sekarang.",
        "Okay, read me the six digits you just got.",
        "Please tell me the TAC that came by SMS.",
    ],
)
def test_credentials_phrases_in_malay_and_english_raise_a_caution(line):
    assert stage_after(line) == ("credentials", "medium")


@pytest.mark.parametrize(
    "line",
    [
        "Selamat pagi puan, ini perkhidmatan pelanggan bank. Kad anda sudah siap, boleh ambil di cawangan.",
        "Hello encik, rider Grab di depan rumah, parcel encik saya letak di pagar ya.",
        "Mak, malam ni nak makan apa? Abang balik lambat sikit, kereta kena servis.",
        "Boleh tak hantar nombor akaun dalam WhatsApp, nanti saya bayar sewa esok.",
        "Thank you for calling the bank. Please hold the line while I check your card limit.",
        "Hi, your delivery is out for delivery today, please be home between two and five.",
        "Can you give me your new address? I want to send the birthday present.",
        "Hey mum, I'm at the airport now, will call you when we land.",
        "Puan, pembayaran bulan ini belum masuk, ada tunggakan kecil pada kad kredit puan.",
        "Abang kena transfer duit sewa kat tuan rumah hari ni, kau dah bayar bahagian kau?",
        "Dah makan? Jangan letak barang kat tepi tangga, nanti orang tersandung.",
        "The booking is under your name, and the hotel can transfer all the luggage to your room.",
        "Saya dari bank, panggilan ini direkodkan. Akaun anda di bawah Bank Negara Malaysia dilindungi PIDM.",
        "Encik, pegawai polis trafik yang tahan encik tadi tinggalkan nombor telefon dia untuk saman.",
    ],
)
def test_ordinary_calls_in_malay_english_and_mandarin_raise_nothing(line):
    assert stage_after(line) == ("none", "low")
