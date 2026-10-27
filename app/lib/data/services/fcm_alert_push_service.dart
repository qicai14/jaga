import 'dart:async';
import 'dart:ui' show Locale;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import '../models/family_alert.dart';
import '../models/onboarding_progress.dart';
import '../repositories/onboarding_repository.dart';
import 'alert_notifier.dart';
import 'alert_push_service.dart';
import 'key_value_store.dart';

/// The data key that holds the FamilyAlert as a JSON string (FCM data values
/// are strings). See design/family.md section 3.
const familyAlertDataKey = 'familyAlert';

/// The alert in a push's data map, or null when it is missing or unparseable.
/// Bad payloads are logged and dropped, never shown with partial data.
FamilyAlert? familyAlertFromData(Map<String, dynamic> data) {
  final raw = data[familyAlertDataKey];
  if (raw is! String) return null;
  try {
    return FamilyAlert.parse(raw);
  } on Object catch (e) {
    // The payload itself is not logged: it holds what the scammer said.
    debugPrint('Dropping a push with a bad family alert: ${e.runtimeType}');
    return null;
  }
}

/// Family alerts from FCM data messages. Foreground messages arrive on
/// [alerts]; background and terminated ones go through
/// [familyAlertBackgroundHandler], which shows the notification itself.
class FcmAlertPushService implements AlertPushService {
  FcmAlertPushService([FirebaseMessaging? messaging])
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  @override
  Stream<FamilyAlert> get alerts => FirebaseMessaging.onMessage
      .map((m) => familyAlertFromData(m.data))
      .where((a) => a != null)
      .cast<FamilyAlert>();

  /// Data pushes never launch the app themselves: the notification the
  /// background handler shows does, and the notifier reads that tap.
  @override
  Future<FamilyAlert?> launchAlert() async => null;

  // The FCM token and its refresh stream, for the server registration that
  // comes with contracts v1. The plugin deprecates them for register() and
  // onRegistered (an Installation ID); the server's Admin SDK sends to tokens,
  // so revisit when contracts v1 picks the identifier.
  // ignore: deprecated_member_use
  Future<String?> token() => _messaging.getToken();

  // ignore: deprecated_member_use
  Stream<String> get tokenRefresh => _messaging.onTokenRefresh;
}

/// Runs in its own isolate when the app is in the background or terminated.
@pragma('vm:entry-point')
Future<void> familyAlertBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await showBackgroundAlert(message.data, const SecureStore());
}

/// Shows the notification for a pushed alert, naming the person linked in
/// [store] (the record onboarding wrote). Nothing is shown without a link.
Future<void> showBackgroundAlert(
  Map<String, dynamic> data,
  KeyValueStore store,
) async {
  final alert = familyAlertFromData(data);
  if (alert == null) return;
  final raw = await store.read(onboardingProgressKey);
  if (raw == null) return;
  final progress = OnboardingProgress.parse(raw);
  final person = progress.link;
  if (person == null) return;
  final notifier = LocalAlertNotifier(locale: () => Locale(progress.language));
  // The permission is asked for in onboarding; a background isolate has no activity to ask from.
  await notifier.init(askPermission: false);
  await notifier.show(alert, person);
}

/// Registered once in `main`, before `runApp`.
void registerFcmBackgroundHandler() =>
    FirebaseMessaging.onBackgroundMessage(familyAlertBackgroundHandler);
