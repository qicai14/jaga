import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'app.dart';
import 'core/haptics/vibration_buzzer.dart';
import 'core/l10n/gen/app_localizations.dart';
import 'data/repositories/onboarding_repository.dart';
import 'data/repositories/pin_repository.dart';
import 'data/services/alert_notifier.dart';
import 'data/services/alert_push_service.dart';
import 'data/services/auth_service.dart';
import 'data/services/copilot_pause_service.dart';
import 'data/services/device_setup_service.dart';
import 'data/services/dialer_service.dart';
import 'data/services/fcm_alert_push_service.dart';
import 'data/services/key_value_store.dart';
import 'data/services/onboarding_api_service.dart';
import 'data/services/share_service.dart';
import 'data/services/timeline_service.dart';
import 'firebase_options.dart';

/// Starts Firebase. False (logged) when it is unreachable, so the app falls
/// back to Fakes instead of crashing. [init] is a seam for tests.
Future<bool> initFirebase([Future<void> Function()? init]) async {
  try {
    await (init ??
        () => Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ))();
    return true;
  } on Object catch (e) {
    debugPrint('Firebase is unavailable, using Fake push and auth: $e');
    return false;
  }
}

/// The real services, except the server APIs (onboarding, pause, timeline),
/// which are still Fakes. Push and auth are real when Firebase starts.
Future<AppDependencies> createDependencies() async {
  // TODO(#1): the real onboarding API, pause and timeline services replace these Fakes once
  // contracts v1 land.
  debugPrint(
    'Jaga is running on Fake onboarding API, pause and timeline services.',
  );
  final firebaseReady = await initFirebase();
  final AuthService auth;
  final AlertPushService push;
  if (firebaseReady) {
    registerFcmBackgroundHandler();
    final fcm = FcmAlertPushService();
    auth = FirebaseAuthService();
    push = fcm;
    unawaited(_signIn(auth, fcm));
  } else {
    auth = const FakeAuthService();
    push = FakeAlertPushService();
  }
  final pin = PinRepository(store: const SecureStore());
  final onboarding = await OnboardingRepository.load(
    store: const SecureStore(),
    api: FakeOnboardingApiService(),
    pin: pin,
    firstLanguage: _phoneLanguageOr('ms'),
  );
  final notifier = LocalAlertNotifier(
    locale: () => Locale(onboarding.progress.value.language),
  );
  return AppDependencies(
    onboarding: onboarding,
    pin: pin,
    deviceSetup: const AndroidDeviceSetupService(),
    dialer: const UrlDialerService(),
    buzzer: VibrationBuzzer(),
    share: const SharePlusService(),
    alertPush: push,
    alertNotifier: notifier,
    pause: FakeCopilotPauseService(),
    timeline: FakeTimelineService(),
    initAlerts: notifier.init,
  );
}

/// Signs in anonymously without holding up startup; a failure is logged and
/// retried by the next `ensureSignedIn`. Debug builds also log the uid and
/// FCM token, for checking Firebase on a device.
Future<void> _signIn(AuthService auth, FcmAlertPushService fcm) async {
  try {
    final uid = await auth.ensureSignedIn();
    if (kDebugMode) debugPrint('Jaga uid: $uid');
  } on Object catch (e) {
    debugPrint('Jaga anonymous sign-in failed: $e');
  }
  if (!kDebugMode) return;
  try {
    debugPrint('Jaga FCM token: ${await fcm.token()}');
  } on Object catch (e) {
    debugPrint('Jaga FCM token failed: $e');
  }
}

/// The phone's language when Jaga speaks it: preselected on the first screen.
String _phoneLanguageOr(String fallback) {
  final code = PlatformDispatcher.instance.locale.languageCode;
  return AppLocalizations.supportedLocales.any((l) => l.languageCode == code)
      ? code
      : fallback;
}
