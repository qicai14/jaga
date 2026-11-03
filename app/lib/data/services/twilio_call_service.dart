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
  }) : _events = events ?? _platform.callEventsListener,
       _activeCall = activeCall ?? (() => _platform.call.activeCall),
       _now = now ?? DateTime.now {
    _sub = _events.listen(_onEvent);
  }

  static TwilioVoicePlatform get _platform => TwilioVoicePlatform.instance;

  final Future<String?> Function() fcmToken;
  final ActiveCall? Function() _activeCall;
  final DateTime Function() _now;
  final Stream<CallEvent> _events;
  final _controller = StreamController<CallSnapshot>.broadcast(sync: true);
  late StreamSubscription<CallEvent> _sub;
  CallSnapshot _snapshot = const CallSnapshot();
  // Set once per call when we re-listen to recover the callId; cleared when the call is no longer live.
  bool _relistened = false;
  bool _disposed = false;

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

  // The parent call's SID, sent by /twilio/voice as a <Parameter>; null on the Fake path, so no stage stream.
  // The Answer event carries it, the 4-token Connected event does not, so reduceCallEvent keeps it from answer.
  // Answered from the ring screen before Dart listens, the plugin buffers only the last call event, so Connected
  // replaces Answer and the callId is lost; _onEvent then re-listens to get it back.
  static String? _callId(ActiveCall? call) =>
      call?.customParams?['callId'] as String?;

  /// A fresh listen with nothing buffered makes the plugin re-emit the active call as a 5-token Connected, with
  /// its custom params (TwilioVoicePlugin.onListen, emitActiveCallState).
  Future<void> _relisten() async {
    _relistened = true;
    await _sub.cancel();
    // dispose() may have run during the cancel.
    if (!_disposed) _sub = _events.listen(_onEvent);
  }

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
    if (!next.live) _relistened = false;
    if (event == CallEvent.connected && next.callId == null && !_relistened) {
      _relisten().catchError(
        (Object e) => debugPrint('Jaga could not re-listen for the callId: $e'),
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
    _disposed = true;
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
      // A late ring event must not knock a live call back to ringing.
      if (snapshot.live) return snapshot;
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
        callId: callId,
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
        // A repeat of the end keeps what the screen is showing.
        CallPhase.ended || CallPhase.failed => snapshot,
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
