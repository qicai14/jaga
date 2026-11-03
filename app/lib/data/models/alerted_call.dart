import 'family_alert.dart';
import 'stage.dart';
import 'stage_update.dart' show Risk;

// Parsed from `contracts/stage-timeline.schema.json` (ADR 0008). An event's
// `source` is not shown, and `endedAt` is kept only as [AlertedCall.live].

/// One call the family was alerted about, as a row of the co-pilot home.
class AlertedCall {
  const AlertedCall({
    required this.callId,
    required this.at,
    required this.stage,
    this.claimedAgency,
    this.live = false,
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
      live: json['endedAt'] == null,
    );
  }

  /// The call behind a family alert. An alert only exists while the call is on,
  /// so it is live (Delete stays off).
  factory AlertedCall.fromAlert(FamilyAlert alert) => AlertedCall(
    callId: alert.callId,
    at: alert.at,
    stage: alert.stage,
    claimedAgency: alert.claimedAgency,
    live: true,
  );

  final String callId;
  final DateTime at;
  final Stage stage;
  final String? claimedAgency;

  /// The call has not ended (`endedAt` null): the server refuses to delete it.
  final bool live;
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
