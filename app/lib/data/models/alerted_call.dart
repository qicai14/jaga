import 'stage.dart';
import 'stage_update.dart' show Risk;

// Parsed from `contracts/stage-timeline.schema.json` (ADR 0008). The timeline's
// `endedAt` and an event's `source` are not shown, so they are not kept.

/// One call the family was alerted about, as a row of the co-pilot home.
class AlertedCall {
  const AlertedCall({
    required this.callId,
    required this.at,
    required this.stage,
    this.claimedAgency,
  });

  /// A row from `GET /timelines`: [at] is `startedAt`, [stage] the latest event's.
  factory AlertedCall.fromJson(Map<String, dynamic> json) {
    final events = json['events'] as List;
    return AlertedCall(
      callId: json['callId'] as String,
      at: DateTime.parse(json['startedAt'] as String),
      stage: events.isEmpty
          ? Stage.none
          : Stage.fromJson((events.last as Map)['stage'] as String),
      claimedAgency: json['claimedAgency'] as String?,
    );
  }

  final String callId;
  final DateTime at;
  final Stage stage;
  final String? claimedAgency;
}

/// One step of a call's stage timeline: stage, time, risk and masked quotes.
/// Never the transcript or audio (GLOSSARY: Stage timeline).
class TimelineEvent {
  const TimelineEvent({
    required this.at,
    required this.stage,
    required this.risk,
    this.quotes = const [],
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> json) => TimelineEvent(
    at: DateTime.parse(json['at'] as String),
    stage: Stage.fromJson(json['stage'] as String),
    risk: Risk.fromJson(json['risk'] as String),
    quotes: [...?(json['evidence'] as List?)?.cast<String>()],
  );

  final DateTime at;
  final Stage stage;
  final Risk risk;
  final List<String> quotes;
}
