import 'dart:async';

import '../models/call_snapshot.dart';

/// The Jaga line call on this phone. The real one is [TwilioCallService].
abstract class CallService {
  /// Every change of the call, oldest first.
  Stream<CallSnapshot> get snapshots;

  /// The call as it is now (an app started by the call finds it already on).
  Future<CallSnapshot> current();

  Future<void> hangUp();
  Future<void> setMuted(bool muted);
  Future<void> setSpeaker(bool on);

  /// Lets Twilio ring this phone. Protected role only.
  Future<void> register(String accessToken);
}

/// Scripted for tests and the debug gallery: [emit] plays what the phone would report.
class FakeCallService implements CallService {
  FakeCallService([this._snapshot = const CallSnapshot()]);

  CallSnapshot _snapshot;
  final _controller = StreamController<CallSnapshot>.broadcast(sync: true);
  int hangUps = 0;
  final mutedCalls = <bool>[];
  final speakerCalls = <bool>[];
  final registered = <String>[];

  @override
  Stream<CallSnapshot> get snapshots => _controller.stream;

  @override
  Future<CallSnapshot> current() async => _snapshot;

  void emit(CallSnapshot snapshot) {
    _snapshot = snapshot;
    _controller.add(snapshot);
  }

  @override
  Future<void> hangUp() async {
    hangUps++;
    emit(
      _snapshot.copyWith(
        phase: _snapshot.connectedAt == null
            ? CallPhase.failed
            : CallPhase.ended,
        endedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> setMuted(bool muted) async {
    mutedCalls.add(muted);
    emit(_snapshot.copyWith(muted: muted));
  }

  @override
  Future<void> setSpeaker(bool on) async {
    speakerCalls.add(on);
    emit(_snapshot.copyWith(speakerOn: on));
  }

  @override
  Future<void> register(String accessToken) async =>
      registered.add(accessToken);

  void dispose() => _controller.close();
}
