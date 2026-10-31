import 'package:flutter/foundation.dart';

import '../../../data/models/alerted_call.dart';
import '../../../data/models/linked_person.dart';
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
  }) {
    load();
  }

  final LinkedPerson person;
  final CopilotPauseService _pause;
  final TimelineService _timeline;

  bool _disposed = false;
  LoadStatus _status = LoadStatus.loading;
  bool _pauseActive = false;
  List<AlertedCall> _calls = const [];

  LoadStatus get status => _status;
  bool get pauseActive => _pauseActive;
  List<AlertedCall> get calls => _calls;

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
    try {
      final active = await _pause.isActive();
      final calls = await _timeline.calls();
      if (_disposed) return;
      _pauseActive = active;
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
    super.dispose();
  }
}
