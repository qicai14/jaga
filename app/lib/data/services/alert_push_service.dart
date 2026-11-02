import 'dart:async';

import '../models/family_alert.dart';

/// Where family alerts arrive from. The FCM implementation waits for the
/// team's Firebase project.
abstract class AlertPushService {
  Stream<FamilyAlert> get alerts;

  /// The alert that launched the app from a terminated state, if any.
  Future<FamilyAlert?> launchAlert();
}

/// Scripted alerts for tests and the debug gallery.
class FakeAlertPushService implements AlertPushService {
  FakeAlertPushService({this.launch});

  final FamilyAlert? launch;
  final _controller = StreamController<FamilyAlert>.broadcast(sync: true);

  @override
  Stream<FamilyAlert> get alerts => _controller.stream;

  @override
  Future<FamilyAlert?> launchAlert() async => launch;

  void emit(FamilyAlert alert) => _controller.add(alert);

  void dispose() => _controller.close();
}
