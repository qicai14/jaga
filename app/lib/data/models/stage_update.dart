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

/// Server to app, during a call: `contracts/stage-update.schema.json` (v1, ADR 0007).
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
    required this.source,
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
    source: Source.fromJson(json['source'] as String),
  );

  factory StageUpdate.parse(String raw) =>
      StageUpdate.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  final String callId;
  final Stage stage;
  final Risk risk;
  final DateTime at;
  final String? claimedAgency;

  /// Non-null only at high risk: command language, then English. The official
  /// number is inside [counterMove].
  final String? command;
  final String? counterMove;
  final List<String> evidence;
  final Source source;
}
