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
    _sub = _alerts.alerts.listen((_) => load());
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
  List<AlertedCall> _calls = const [];

  LoadStatus get status => _status;
  bool get pauseActive => _pauseActive;

  /// Live calls first (newest first), then the rest in service order.
  List<AlertedCall> get calls => [
    ...(_calls.where((c) => c.live).toList()
      ..sort((a, b) => b.at.compareTo(a.at))),
    ..._calls.where((c) => !c.live),
  ];

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
      if (_disposed) return;
      _pauseActive = active ?? _pauseActive;
      _calls = calls;
      _status = LoadStatus.loaded;
    } on NetworkException {
      if (_disposed) return;
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _sub.cancel();
    super.dispose();
  }
}
