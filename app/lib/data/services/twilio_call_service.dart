import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:twilio_voice/twilio_voice.dart';

import '../models/call_snapshot.dart';
import 'call_service.dart';

/// The only file that imports `twilio_voice`. Maps its call events to [CallSnapshot]s.
class TwilioCallService implements CallService {
  /// [events], [activeCall] and [fcmToken] are seams for tests; the defaults are the plugin's and Firebase's.
  TwilioCallService({
    required this.fcmToken,
    Stream<CallEvent>? events,
    ActiveCall? Function()? activeCall,
    DateTime Function()? now,
  }) : _activeCall = activeCall ?? (() => _platform.call.activeCall),
       _now = now ?? DateTime.now {
    _sub = (events ?? _platform.callEventsListener).listen(_onEvent);
  }

  static TwilioVoicePlatform get _platform => TwilioVoicePlatform.instance;

  final Future<String?> Function() fcmToken;
  final ActiveCall? Function() _activeCall;
  final DateTime Function() _now;
  final _controller = StreamController<CallSnapshot>.broadcast(sync: true);
  late final StreamSubscription<CallEvent> _sub;
  CallSnapshot _snapshot = const CallSnapshot();

  @override
  Stream<CallSnapshot> get snapshots => _controller.stream;

  @override
  Future<CallSnapshot> current() async {
    // The app can start because a call is already on (answered with the app killed).
    if (_snapshot.phase == CallPhase.idle && await _platform.call.isOnCall()) {
      final active = _activeCall();
      _snapshot = _snapshot.copyWith(
        phase: CallPhase.active,
        callerLabel: _label(active),
        callId: _callId(active),
        connectedAt: _now(),
        muted: await _platform.call.isMuted() ?? false,
        speakerOn: await _platform.call.isOnSpeaker() ?? false,
      );
    }
    return _snapshot;
  }

  static String? _label(ActiveCall? call) {
    final name = call?.customParams?['__TWI_CALLER_NAME'] as String?;
    final label = name ?? call?.fromFormatted;
    return label == null || label.isEmpty ? null : label;
  }

  static String? _callId(ActiveCall? call) =>
      call?.customParams?['callId'] as String?;

  void _onEvent(CallEvent event) {
    final active = _activeCall();
    final next = reduceCallEvent(
      _snapshot,
      event,
      now: _now(),
      label: _label(active),
      callId: _callId(active),
    );
    // The plugin turns the speaker on at ring: the answer sets it off, explicitly.
    if (event == CallEvent.answer) {
      setSpeaker(false).catchError(
        (Object e) => debugPrint('Jaga could not set the speaker: $e'),
      );
    }
    if (identical(next, _snapshot)) return;
    _snapshot = next;
    _controller.add(next);
  }

  @override
  Future<void> hangUp() async {
    await _platform.call.hangUp();
  }

  @override
  Future<void> setMuted(bool muted) async {
    await _platform.call.toggleMute(muted);
  }

  @override
  Future<void> setSpeaker(bool on) async {
    await _platform.call.toggleSpeaker(on);
  }

  @override
  Future<void> register(String accessToken) async {
    final ok = await _platform.setTokens(
      accessToken: accessToken,
      deviceToken: await fcmToken(),
    );
    // Never the token itself in a log.
    if (ok != true) debugPrint('Jaga line registration was refused.');
  }

  Future<void> dispose() async {
    await _sub.cancel();
    await _controller.close();
  }
}

/// The phone's call events as call phases (call.md section 6). Returns [snapshot] itself when nothing changes.
@visibleForTesting
CallSnapshot reduceCallEvent(
  CallSnapshot snapshot,
  CallEvent event, {
  required DateTime now,
  String? label,
  String? callId,
}) {
  switch (event) {
    case CallEvent.incoming:
    case CallEvent.ringing:
      return CallSnapshot(phase: CallPhase.ringing, callerLabel: label);
    case CallEvent.answer:
      return CallSnapshot(
        phase: CallPhase.connecting,
        callerLabel: label ?? snapshot.callerLabel,
        callId: callId,
      );
    case CallEvent.connected:
    case CallEvent.reconnected:
      return snapshot.copyWith(
        phase: CallPhase.active,
        connectedAt: snapshot.connectedAt ?? now,
      );
    case CallEvent.reconnecting:
      return snapshot.copyWith(phase: CallPhase.reconnecting);
    case CallEvent.callEnded:
      return switch (snapshot.phase) {
        CallPhase.connecting => snapshot.copyWith(
          phase: CallPhase.failed,
          endedAt: now,
        ),
        CallPhase.active || CallPhase.reconnecting => snapshot.copyWith(
          phase: CallPhase.ended,
          endedAt: now,
        ),
        // Rang and was never answered: nothing to show.
        _ => const CallSnapshot(),
      };
    case CallEvent.declined:
    case CallEvent.missedCall:
      return const CallSnapshot();
    case CallEvent.mute:
      return snapshot.copyWith(muted: true);
    case CallEvent.unmute:
      return snapshot.copyWith(muted: false);
    case CallEvent.speakerOn:
      return snapshot.copyWith(speakerOn: true);
    case CallEvent.speakerOff:
      return snapshot.copyWith(speakerOn: false);
    default:
      return snapshot;
  }
}
