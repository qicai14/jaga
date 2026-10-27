import 'package:flutter/foundation.dart';

import '../../../data/models/alerted_call.dart';
import '../../../data/models/scam_hotline.dart';
import '../../../data/services/dialer_service.dart';
import '../../../data/services/network_exception.dart';
import '../../../data/services/timeline_service.dart';
import 'load_status.dart';

/// One call's stage timeline, which the co-pilot may delete.
class StageTimelineViewModel extends ChangeNotifier {
  StageTimelineViewModel({
    required this.call,
    required this._timeline,
    required this._dialer,
  }) {
    load();
  }

  final AlertedCall call;
  final TimelineService _timeline;
  final DialerService _dialer;

  bool _disposed = false;
  bool _deleting = false;
  LoadStatus _status = LoadStatus.loading;
  List<TimelineEvent> _events = const [];

  LoadStatus get status => _status;
  List<TimelineEvent> get events => _events;

  Future<void> load() async {
    _status = LoadStatus.loading;
    notifyListeners();
    try {
      final events = await _timeline.events(call.callId);
      if (_disposed) return;
      _events = events;
      _status = LoadStatus.loaded;
    } on NetworkException {
      if (_disposed) return;
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  /// True once the timeline is gone; false if it could not be deleted.
  Future<bool> delete() async {
    if (_deleting) return false;
    _deleting = true;
    try {
      await _timeline.delete(call.callId);
      return true;
    } on NetworkException {
      return false;
    } finally {
      _deleting = false;
    }
  }

  Future<void> callHotline() => _dialer.dial(scamHotline);

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
