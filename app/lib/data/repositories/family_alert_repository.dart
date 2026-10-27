import 'dart:async';

import '../models/family_alert.dart';
import '../models/linked_person.dart';
import '../services/alert_notifier.dart';
import '../services/alert_push_service.dart';

/// Keeps the latest alert per call and notifies once per push. A later push for
/// the same call replaces the earlier one, but the stage only ever rises.
class FamilyAlertRepository {
  FamilyAlertRepository({
    required AlertPushService push,
    required this._notifier,
    required this.person,
  }) : _push = push {
    _sub = push.alerts.listen((alert) {
      final merged = receive(alert);
      _merged.add(merged);
      _notifier.show(merged, person);
    });
  }

  final AlertPushService _push;
  final AlertNotifier _notifier;
  final LinkedPerson person;
  final _latest = <String, FamilyAlert>{};
  final _merged = StreamController<FamilyAlert>.broadcast(sync: true);
  late final StreamSubscription<FamilyAlert> _sub;

  /// Every push, merged with what we already hold for its call.
  Stream<FamilyAlert> get alerts => _merged.stream;

  /// The alert that launched the app from a terminated state, if any.
  Future<FamilyAlert?> launchAlert() => _push.launchAlert();

  /// Merges [alert] into what is held for its call and returns the result.
  /// Fields come from the newer alert (by `at`); the stage never goes down.
  FamilyAlert receive(FamilyAlert alert) {
    final old = _latest[alert.callId];
    if (old == null) return _latest[alert.callId] = alert;
    final newer = alert.at.isBefore(old.at) ? old : alert;
    final stage = alert.stage.index > old.stage.index ? alert.stage : old.stage;
    return _latest[alert.callId] = newer.withStage(stage);
  }

  void dispose() {
    _sub.cancel();
    _merged.close();
  }
}
