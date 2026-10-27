import 'dart:convert';

import 'stage.dart';

enum FamilyAlertKind {
  alert,

  /// Follow-up: Jaga now thinks the call is less likely to be a scam.
  mayBeGenuine;

  static FamilyAlertKind fromJson(String value) =>
      FamilyAlertKind.values.firstWhere((k) => k.name == value);
}

/// Server to family co-pilot: `contracts/family-alert.schema.json` (draft v0).
/// Summary and masked quotes only, never the transcript. Unknown enum values throw.
class FamilyAlert {
  const FamilyAlert({
    required this.callId,
    required this.protectedUserName,
    required this.stage,
    required this.summary,
    required this.at,
    this.claimedAgency,
    this.quotes = const [],
    this.kind = FamilyAlertKind.alert,
  });

  factory FamilyAlert.fromJson(Map<String, dynamic> json) => FamilyAlert(
    callId: json['callId'] as String,
    protectedUserName: json['protectedUserName'] as String,
    stage: Stage.fromJson(json['stage'] as String),
    summary: json['summary'] as String,
    at: DateTime.parse(json['at'] as String),
    claimedAgency: json['claimedAgency'] as String?,
    quotes: [...?(json['quotes'] as List?)?.cast<String>()],
    // Not in contract v0 yet (requested from contracts #1): absent means alert.
    kind: json['kind'] == null
        ? FamilyAlertKind.alert
        : FamilyAlertKind.fromJson(json['kind'] as String),
  );

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

  FamilyAlert withStage(Stage value) => FamilyAlert(
    callId: callId,
    protectedUserName: protectedUserName,
    stage: value,
    summary: summary,
    at: at,
    claimedAgency: claimedAgency,
    quotes: quotes,
    kind: kind,
  );
}
