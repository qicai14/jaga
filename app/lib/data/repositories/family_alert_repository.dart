import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/family_alert.dart';
import '../models/linked_person.dart';
import '../services/alert_notifier.dart';
import '../services/alert_push_service.dart';

/// Keeps the latest alert per call and notifies once per push that changes
/// something. A later push for the same call replaces the earlier one, but the
/// stage only ever rises.
class FamilyAlertRepository {
  FamilyAlertRepository({
    required AlertPushService push,
    required this._notifier,
    required this.person,
  }) : _push = push {
    _sub = push.alerts.listen((alert) {
      final before = _latest[alert.callId];
      final merged = receive(alert);
      if (identical(merged, before)) return; // a redelivery or a stale push
      _merged.add(merged);
      unawaited(
        _notifier
            .show(merged, person)
            .catchError(
              (Object e) => debugPrint('Could not show the notification: $e'),
            ),
      );
    });
  }

  final AlertPushService _push;
  final AlertNotifier _notifier;
  final LinkedPerson person;
  final _latest = <String, FamilyAlert>{};
  final _merged = StreamController<FamilyAlert>.broadcast();
  late final StreamSubscription<FamilyAlert> _sub;

  /// Every push that changed what we hold for its call, merged.
  Stream<FamilyAlert> get alerts => _merged.stream;

  /// The alert that launched the app from a terminated state, if any.
  Future<FamilyAlert?> launchAlert() => _push.launchAlert();

  /// Merges [alert] into what is held for its call and returns the result:
  /// the identical held instance when nothing changed. Fields come from the
  /// newer alert by `at` (the incoming one on a tie); the stage never goes down.
  FamilyAlert receive(FamilyAlert alert) {
    final old = _latest[alert.callId];
    if (old == null) return _latest[alert.callId] = alert;
    final newer = alert.at.isBefore(old.at) ? old : alert;
    // Credentials outranks money by index on purpose, so the label shows
    // credentials even though the glossary ties them.
    final stage = alert.stage.index > old.stage.index ? alert.stage : old.stage;
    final merged = newer.withStage(stage);
    return merged == old ? old : _latest[alert.callId] = merged;
  }

  void dispose() {
    _sub.cancel();
    _merged.close();
  }
}
