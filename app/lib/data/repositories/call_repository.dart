import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/call_snapshot.dart';
import '../services/call_service.dart';
import '../services/voice_token_service.dart';

/// The call this phone is on, and the Twilio registration that lets calls ring.
class CallRepository {
  CallRepository({
    required this._service,
    required this._tokens,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// A new token is fetched this long before the old one expires.
  static const refreshBefore = Duration(minutes: 5);
  static const retryAfter = Duration(minutes: 1);

  final CallService _service;
  final VoiceTokenService _tokens;
  final DateTime Function() _now;
  final _snapshot = ValueNotifier(const CallSnapshot());
  StreamSubscription<CallSnapshot>? _sub;
  Timer? _refresh;

  ValueListenable<CallSnapshot> get snapshot => _snapshot;

  /// Protected role only: picks up a call already on, then keeps the registration fresh.
  Future<void> start() async {
    await watch();
    await _register();
  }

  /// Follows the call without registering (the debug gallery and tests).
  Future<void> watch() async {
    _sub = _service.snapshots.listen((s) => _snapshot.value = s);
    _snapshot.value = await _service.current();
  }

  Future<void> _register() async {
    var wait = retryAfter;
    try {
      final token = await _tokens.fetch();
      await _service.register(token.token);
      final due = token.expiresAt.difference(_now()) - refreshBefore;
      wait = due > retryAfter ? due : retryAfter;
    } on Object catch (e) {
      debugPrint('Jaga line registration failed, retrying: ${e.runtimeType}');
    }
    _refresh = Timer(wait, _register);
  }

  Future<void> hangUp() => _service.hangUp();
  Future<void> setMuted(bool muted) => _service.setMuted(muted);
  Future<void> setSpeaker(bool on) => _service.setSpeaker(on);

  /// Stops listening and refreshing; [start] can run again.
  void stop() {
    _refresh?.cancel();
    _sub?.cancel();
  }

  void dispose() {
    stop();
    _snapshot.dispose();
  }
}
