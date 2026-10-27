import 'family_alert.dart';
import 'stage.dart';
import 'stage_update.dart';

// PROVISIONAL (#1): the stage-timeline list and event shapes are not in
// contracts v0. Both models are derived from the v0 fields they will most
// likely reuse, so only these two factories change when the contract lands.

/// One call the family was alerted about, as a row of the co-pilot home.
class AlertedCall {
  const AlertedCall({
    required this.callId,
    required this.at,
    required this.stage,
    this.claimedAgency,
  });

  /// The latest alert of a call: when it began, how far it got, who they claimed to be.
  factory AlertedCall.fromAlert(FamilyAlert alert) => AlertedCall(
    callId: alert.callId,
    at: alert.at,
    stage: alert.stage,
    claimedAgency: alert.claimedAgency,
  );

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

  factory TimelineEvent.fromStageUpdate(StageUpdate update) => TimelineEvent(
    at: update.at,
    stage: update.stage,
    risk: update.risk,
    quotes: update.evidence,
  );

  final DateTime at;
  final Stage stage;
  final Risk risk;
  final List<String> quotes;
}
