"""The phrase library and official contacts in the Malaysia region pack (#6)."""

from datetime import date

import pytest

from jaga.stages import RANK, load_pack, official_contact, phrase

STAGES = [s for s in RANK if s != "none"]
LANGS = ["ms", "en", "zh", "ta"]


def entries(pack):
    for stage in STAGES:
        lib = pack["library"][stage]
        yield stage, lib["command"], True
        for move in lib["counterMoves"]:
            yield stage, move, False


def test_every_stage_has_a_command_and_counter_move_in_four_languages():
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
            assert all(entry["text"][lang].endswith(f" {en}") for lang in ("ms", "zh", "ta"))


def test_machine_drafted_languages_are_marked_for_native_review():
    review = load_pack("my")["libraryReview"]
    assert all(review[lang].strip() for lang in ("ms", "zh", "ta"))
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
