import 'dart:convert';

import 'stage.dart';

enum Risk {
  low,
  medium,
  high;

  static Risk fromJson(String value) =>
      Risk.values.firstWhere((r) => r.name == value);
}

enum Source {
  rules,
  spark;

  static Source fromJson(String value) =>
      Source.values.firstWhere((s) => s.name == value);
}

/// Server to app, during a call: `contracts/stage-update.schema.json` (draft v0).
/// Unknown enum values throw (contract drift).
class StageUpdate {
  const StageUpdate({
    required this.callId,
    required this.stage,
    required this.risk,
    required this.at,
    this.claimedAgency,
    this.command,
    this.counterMove,
    this.evidence = const [],
    this.source,
    this.commandEnglish,
    this.counterMoveEnglish,
    this.officialNumber,
  });

  factory StageUpdate.fromJson(Map<String, dynamic> json) => StageUpdate(
    callId: json['callId'] as String,
    stage: Stage.fromJson(json['stage'] as String),
    risk: Risk.fromJson(json['risk'] as String),
    at: DateTime.parse(json['at'] as String),
    claimedAgency: json['claimedAgency'] as String?,
    command: json['command'] as String?,
    counterMove: json['counterMove'] as String?,
    evidence: [...?(json['evidence'] as List?)?.cast<String>()],
    source: json['source'] == null
        ? null
        : Source.fromJson(json['source'] as String),
    commandEnglish: json['commandEnglish'] as String?,
    counterMoveEnglish: json['counterMoveEnglish'] as String?,
    officialNumber: json['officialNumber'] as String?,
  );

  factory StageUpdate.parse(String raw) =>
      StageUpdate.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  final String callId;
  final Stage stage;
  final Risk risk;
  final DateTime at;
  final String? claimedAgency;

  /// Non-null only at high risk, in the user's language (phrase library, ADR 0006).
  final String? command;
  final String? counterMove;
  final List<String> evidence;
  final Source? source;

  // Not in contract v0 yet (requested from contracts #1). Null until it lands;
  // the elements that show them are hidden when null.
  final String? commandEnglish;
  final String? counterMoveEnglish;
  final String? officialNumber;
}
