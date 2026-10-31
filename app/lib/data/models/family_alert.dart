import 'dart:convert';

import 'package:flutter/foundation.dart' show listEquals;

import 'stage.dart';

enum FamilyAlertKind {
  alert,

  /// Follow-up: Jaga now thinks the call is less likely to be a scam.
  mayBeGenuine;

  static FamilyAlertKind fromJson(String value) =>
      FamilyAlertKind.values.firstWhere((k) => k.name == value);
}

/// Server to family co-pilot: `contracts/family-alert.schema.json` (v1).
/// Summary and masked quotes only, never the transcript. Unknown enum values throw.
class FamilyAlert {
  const FamilyAlert({
    required this.callId,
    required this.protectedUserName,
    required this.stage,
    required this.summary,
    required this.at,
    required this.kind,
    this.claimedAgency,
    this.quotes = const [],
  });

  factory FamilyAlert.fromJson(Map<String, dynamic> json) => FamilyAlert(
    callId: json['callId'] as String,
    protectedUserName: json['protectedUserName'] as String,
    stage: _stageFrom(json['stage'] as String),
    summary: json['summary'] as String,
    at: DateTime.parse(json['at'] as String),
    claimedAgency: json['claimedAgency'] as String?,
    quotes: [...?(json['quotes'] as List?)?.cast<String>()],
    kind: FamilyAlertKind.fromJson(json['kind'] as String),
  );

  /// The contract's stage enum starts at isolation: `none` is never sent.
  static Stage _stageFrom(String value) {
    final stage = Stage.fromJson(value);
    if (stage == Stage.none) throw const FormatException('stage none');
    return stage;
  }

  factory FamilyAlert.parse(String raw) =>
      FamilyAlert.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  final String callId;
  final String protectedUserName;
  final Stage stage;
  final String summary;
  final DateTime at;
  final String? claimedAgency;
  final List<String> quotes;
  final FamilyAlertKind kind;

  Map<String, dynamic> toJson() => {
    'callId': callId,
    'protectedUserName': protectedUserName,
    'stage': stage.toJson(),
    'summary': summary,
    'at': at.toUtc().toIso8601String(),
    'claimedAgency': claimedAgency,
    'quotes': quotes,
    'kind': kind.name,
  };

  FamilyAlert withStage(Stage value) => value == stage
      ? this
      : FamilyAlert(
          callId: callId,
          protectedUserName: protectedUserName,
          stage: value,
          summary: summary,
          at: at,
          claimedAgency: claimedAgency,
          quotes: quotes,
          kind: kind,
        );

  @override
  bool operator ==(Object other) =>
      other is FamilyAlert &&
      callId == other.callId &&
      protectedUserName == other.protectedUserName &&
      stage == other.stage &&
      summary == other.summary &&
      at == other.at &&
      claimedAgency == other.claimedAgency &&
      kind == other.kind &&
      listEquals(quotes, other.quotes);

  @override
  int get hashCode => Object.hash(
    callId,
    protectedUserName,
    stage,
    summary,
    at,
    claimedAgency,
    kind,
    Object.hashAll(quotes),
  );
}
