import 'package:flutter/foundation.dart';

enum CallPhase {
  idle,
  ringing,
  connecting,
  active,
  reconnecting,
  ended,
  failed,
}

/// Where the Jaga line call is now. App-internal: it is built from the phone's call events.
@immutable
class CallSnapshot {
  const CallSnapshot({
    this.phase = CallPhase.idle,
    this.callerLabel,
    this.callId,
    this.connectedAt,
    this.endedAt,
    this.muted = false,
    this.speakerOn = false,
  });

  final CallPhase phase;

  /// The caller's number as the phone shows it; null when unknown.
  final String? callerLabel;

  /// Ties this call to the stage stream, when the server sends it.
  final String? callId;
  final DateTime? connectedAt;
  final DateTime? endedAt;
  final bool muted;
  final bool speakerOn;

  /// A call she is on, so the in-call screen belongs in front.
  bool get live =>
      phase == CallPhase.connecting ||
      phase == CallPhase.active ||
      phase == CallPhase.reconnecting;

  CallSnapshot copyWith({
    CallPhase? phase,
    String? callerLabel,
    String? callId,
    DateTime? connectedAt,
    DateTime? endedAt,
    bool? muted,
    bool? speakerOn,
  }) => CallSnapshot(
    phase: phase ?? this.phase,
    callerLabel: callerLabel ?? this.callerLabel,
    callId: callId ?? this.callId,
    connectedAt: connectedAt ?? this.connectedAt,
    endedAt: endedAt ?? this.endedAt,
    muted: muted ?? this.muted,
    speakerOn: speakerOn ?? this.speakerOn,
  );
}
