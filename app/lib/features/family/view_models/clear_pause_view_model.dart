import 'package:flutter/foundation.dart';

import '../../../data/services/copilot_pause_service.dart';
import '../../../data/services/network_exception.dart';

/// One open Clear Jaga Pause sheet. A new sheet starts clean.
class ClearPauseViewModel extends ChangeNotifier {
  ClearPauseViewModel({required this.personName, required this._pause});

  final String personName;
  final CopilotPauseService _pause;

  bool _disposed = false;
  bool _busy = false;
  bool _failed = false;

  bool get busy => _busy;
  bool get failed => _failed;

  /// True once Jaga Pause is cleared; false while busy or on failure.
  Future<bool> clear() async {
    if (_busy) return false;
    _busy = true;
    _failed = false;
    notifyListeners();
    var cleared = false;
    try {
      await _pause.clear();
      cleared = true;
    } on NetworkException {
      _failed = true;
    }
    _busy = false;
    if (!_disposed) notifyListeners();
    return cleared;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
