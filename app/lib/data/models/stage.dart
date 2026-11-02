/// A call's stage, as in `contracts/stage-update.schema.json`. Order is severity;
/// `money` and `credentials` tie as most severe (GLOSSARY.md).
enum Stage {
  none,
  pretext,
  authority,
  fear,
  isolation,
  handoff,
  money,
  credentials;

  /// Parses the contract's wire value; unknown values throw (contract drift).
  static Stage fromJson(String value) =>
      Stage.values.firstWhere((s) => s.name == value);

  String toJson() => name;
}
