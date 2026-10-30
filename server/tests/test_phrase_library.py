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
        "您好，您的包裹被海关扣留了。",
        "你好，你的包裹被海關扣留了。",
    ],
)
def test_pretext_phrases_in_malay_manglish_english_and_mandarin_raise_a_caution(line):
    assert stage_after(line) == ("pretext", "medium")
