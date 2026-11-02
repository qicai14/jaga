import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../data/models/call_snapshot.dart';
import '../../../data/repositories/call_repository.dart';
import '../../../data/services/call_ui_service.dart';

/// The in-call screen's state: the call, the timer, and the three buttons.
class InCallViewModel extends ChangeNotifier with WidgetsBindingObserver {
  InCallViewModel({
    required CallRepository repository,
    required CallUiService callUi,
    DateTime Function()? now,
  }) : _repository = repository,
       _callUi = callUi,
       _now = now ?? DateTime.now {
    WidgetsBinding.instance.addObserver(this);
    repository.snapshot.addListener(_onSnapshot);
    unawaited(callUi.setShowWhenLocked(true));
    _onSnapshot();
  }

  final CallRepository _repository;
  final CallUiService _callUi;
  final DateTime Function() _now;
  Timer? _ticker;
  bool _inForeground = true;
  bool _disposed = false;
  bool? _proximity;

  CallSnapshot get call => _repository.snapshot.value;
  CallPhase get phase => call.phase;
  bool get muted => call.muted;
  bool get speakerOn => call.speakerOn;

  /// Mute and speaker work once the call is connected.
  bool get controlsEnabled =>
      phase == CallPhase.active || phase == CallPhase.reconnecting;

  /// Time on the call: running while active, final once it ended.
  Duration get elapsed {
    final start = call.connectedAt;
    if (start == null) return Duration.zero;
    final end = call.endedAt ?? _now();
    return end.isBefore(start) ? Duration.zero : end.difference(start);
  }

  void _onSnapshot() {
    final ticking = controlsEnabled;
    if (ticking && _ticker == null) {
      _ticker = Timer.periodic(
        const Duration(seconds: 1),
        (_) => notifyListeners(),
      );
    } else if (!ticking) {
      _ticker?.cancel();
      _ticker = null;
    }
    _syncProximity();
    notifyListeners();
  }

  /// Screen off at the ear: only while she can be on the call with the speaker off and Jaga in front.
  void _syncProximity() {
    final want = _inForeground && call.live && !speakerOn;
    if (want == _proximity) return;
    _proximity = want;
    unawaited(_callUi.setProximityLock(want));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _inForeground = state == AppLifecycleState.resumed;
    _syncProximity();
  }

  Future<void> toggleMute() => _repository.setMuted(!muted);
  Future<void> toggleSpeaker() => _repository.setSpeaker(!speakerOn);
  Future<void> hangUp() => _repository.hangUp();
  Future<void> moveToBack() => _callUi.moveToBack();

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _repository.snapshot.removeListener(_onSnapshot);
    _ticker?.cancel();
    unawaited(_callUi.setProximityLock(false));
    unawaited(_callUi.setShowWhenLocked(false));
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }
}
