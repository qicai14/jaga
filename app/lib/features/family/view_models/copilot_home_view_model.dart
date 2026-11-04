import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/models/alerted_call.dart';
import '../../../data/models/family_alert.dart';
import '../../../data/models/linked_person.dart';
import '../../../data/repositories/family_alert_repository.dart';
import '../../../data/services/copilot_pause_service.dart';
import '../../../data/services/network_exception.dart';
import '../../../data/services/timeline_service.dart';
import 'load_status.dart';

/// The co-pilot home: whom they protect, whether Jaga Pause is on, and the
/// calls the family was alerted about.
class CopilotHomeViewModel extends ChangeNotifier {
  CopilotHomeViewModel({
    required this.person,
    required this._pause,
    required this._timeline,
    required this._alerts,
  }) {
    // A new push shows on home without a notification tap.
    _sub = _alerts.alerts.listen((_) => unawaited(_reload()));
    load();
  }

  final LinkedPerson person;
  final CopilotPauseService _pause;
  final TimelineService _timeline;
  final FamilyAlertRepository _alerts;
  late final StreamSubscription<FamilyAlert> _sub;

  bool _disposed = false;
  LoadStatus _status = LoadStatus.loading;
  bool _pauseActive = false;
  List<AlertedCall> _sorted = const [];
  int _generation = 0;

  LoadStatus get status => _status;
  bool get pauseActive => _pauseActive;

  /// Live calls first (newest first), then the rest in service order.
  List<AlertedCall> get calls => _sorted;

  /// Calls still going: every one is shown on Home.
  List<AlertedCall> get liveCalls => [
    for (final c in _sorted)
      if (c.live) c,
  ];

  /// The newest call that has ended, if any.
  AlertedCall? get lastEnded {
    for (final c in _sorted) {
      if (!c.live) return c;
    }
    return null;
  }

  /// The alert held for [callId], if this process has seen one.
  FamilyAlert? heldAlert(String callId) => _alerts.latest(callId);

  /// The sheet cleared it: hide the pause row now, before the reload confirms.
  void markPauseCleared() {
    _pauseActive = false;
    notifyListeners();
  }

  /// Loads the pause status and the calls. Content already on screen stays
  /// while it refreshes; after an error the spinner returns.
  Future<void> load() async {
    final generation = ++_generation;
    if (_status != LoadStatus.loaded) {
      _status = LoadStatus.loading;
      notifyListeners();
    }
    // The pause status loads on its own: if it fails the pause row stays
    // hidden and the timelines still show.
    final pause = _pause.isActive().then<bool?>(
      (v) => v,
      onError: (Object _) => null,
    );
    try {
      final calls = await _timeline.calls();
      final active = await pause;
      // A newer load started meanwhile: its answer wins.
      if (_disposed || generation != _generation) return;
      _pauseActive = active ?? _pauseActive;
      _sorted = [
        ...(calls.where((c) => c.live).toList()
          ..sort((a, b) => b.at.compareTo(a.at))),
        ...calls.where((c) => !c.live),
      ];
      _status = LoadStatus.loaded;
    } on NetworkException {
      if (_disposed || generation != _generation) return;
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  /// A push reloads in the background: nothing may escape unhandled.
  Future<void> _reload() async {
    try {
      await load();
    } catch (e) {
      debugPrint('Could not reload the calls: ${e.runtimeType}');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _sub.cancel();
    super.dispose();
  }
}
