import 'stage.dart';
import 'stage_update.dart' show Risk;

// PROVISIONAL (#1): the stage-timeline list and event shapes are not in
// contracts v0. Both models reuse the v0 fields they will most likely carry:
// an alert's (callId, at, stage, claimedAgency) and a stage update's
// (at, stage, risk, evidence).

/// One call the family was alerted about, as a row of the co-pilot home.
class AlertedCall {
  const AlertedCall({
    required this.callId,
    required this.at,
    required this.stage,
    this.claimedAgency,
  });

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

  final DateTime at;
  final Stage stage;
  final Risk risk;
  final List<String> quotes;
}
