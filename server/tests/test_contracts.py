import json
from pathlib import Path

import pytest
from jsonschema import Draft202012Validator

CONTRACTS = Path(__file__).resolve().parents[2] / "contracts"
FIXTURES = CONTRACTS / "fixtures"
VALID = sorted(p for p in FIXTURES.glob("*/*.json") if p.parent.name != "invalid")
INVALID = sorted(FIXTURES.glob("invalid/*/*.json"))


def validator(path: Path) -> Draft202012Validator:
    schema = json.loads((CONTRACTS / f"{path.parent.name}.schema.json").read_text(encoding="utf-8"))
    if path.parent.name == "pause":
        # pause holds both bodies in $defs; the file name says which one (request-*, response-*)
        schema = schema | {"$ref": "#/$defs/" + path.name.split("-")[0]}
    return Draft202012Validator(schema, format_checker=Draft202012Validator.FORMAT_CHECKER)


def load(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def test_every_schema_is_valid_and_has_fixtures():
    for schema_path in CONTRACTS.glob("*.schema.json"):
        Draft202012Validator.check_schema(json.loads(schema_path.read_text(encoding="utf-8")))
        name = schema_path.name.removesuffix(".schema.json")
        assert list((FIXTURES / name).glob("*.json")), f"no valid fixture for {name}"
        assert list((FIXTURES / "invalid" / name).glob("*.json")), f"no invalid fixture for {name}"


@pytest.mark.parametrize("path", VALID, ids=lambda p: f"{p.parent.name}/{p.name}")
def test_valid_fixture_passes(path):
    validator(path).validate(load(path))


@pytest.mark.parametrize("path", INVALID, ids=lambda p: f"{p.parent.name}/{p.name}")
def test_invalid_fixture_fails(path):
    assert not validator(path).is_valid(load(path))
