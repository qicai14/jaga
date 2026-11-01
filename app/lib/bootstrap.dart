import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'app.dart';
import 'core/config/build_config.dart';
import 'core/haptics/vibration_buzzer.dart';
import 'core/l10n/gen/app_localizations.dart';
import 'data/repositories/call_repository.dart';
import 'data/repositories/onboarding_repository.dart';
import 'data/repositories/pin_repository.dart';
import 'data/services/alert_notifier.dart';
import 'data/services/alert_push_service.dart';
import 'data/services/attention_service.dart';
import 'data/services/auth_service.dart';
import 'data/services/call_service.dart';
import 'data/services/call_ui_service.dart';
import 'data/services/copilot_pause_service.dart';
import 'data/services/device_setup_service.dart';
import 'data/services/dialer_service.dart';
import 'data/services/fcm_alert_push_service.dart';
import 'data/services/key_value_store.dart';
import 'data/services/onboarding_api_service.dart';
import 'data/services/share_service.dart';
import 'data/services/stage_stream_service.dart';
import 'data/services/timeline_service.dart';
import 'data/services/twilio_call_service.dart';
import 'data/services/voice_token_service.dart';
import 'firebase_options.dart';

// Build-time config (--dart-define). Empty means fake mode: no network, no Twilio registration.
const _serverUrl = String.fromEnvironment('JAGA_SERVER_URL');
const _appToken = String.fromEnvironment('JAGA_APP_TOKEN');
const _copilotToken = String.fromEnvironment('JAGA_COPILOT_TOKEN');

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

/// The real services, except the onboarding API, which is still a Fake. Pause
/// and timeline are real with JAGA_SERVER_URL and JAGA_COPILOT_TOKEN. Push and auth are real when Firebase starts.
Future<AppDependencies> createDependencies() async {
  // Each token marks its own build, so the other role's HTTP services below
  // are never created: realCalls needs the app token, realCopilot the co-pilot one.
  final buildRole = BuildRole.from(
    appToken: _appToken.isNotEmpty,
    copilotToken: _copilotToken.isNotEmpty,
  );
  // TODO(#1): the real onboarding API replaces this Fake once its contract lands.
  final realCopilot = _serverUrl.isNotEmpty && _copilotToken.isNotEmpty;
  debugPrint(
    realCopilot
        ? 'Jaga is running on a Fake onboarding API.'
        : 'Jaga is running on Fake onboarding API, pause and timeline services: '
              'set JAGA_SERVER_URL and JAGA_COPILOT_TOKEN with --dart-define.',
  );
  final firebaseReady = await initFirebase();
  final AuthService auth;
  final AlertPushService push;
  FcmAlertPushService? fcmService;
  if (firebaseReady) {
    registerFcmBackgroundHandler();
    final fcm = FcmAlertPushService();
    auth = FirebaseAuthService();
    push = fcm;
    fcmService = fcm;
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
  // The real Jaga line needs Firebase (its push token), the server and the app secret.
  final realCalls =
      fcmService != null && _serverUrl.isNotEmpty && _appToken.isNotEmpty;
  if (!realCalls) {
    debugPrint(
      'Jaga line calls are off: set JAGA_SERVER_URL and JAGA_APP_TOKEN with --dart-define.',
    );
  }
  final stageStream = realCalls
      ? WebSocketStageStreamService(Uri.parse(_serverUrl))
      : FakeStageStreamService();
  final call = CallRepository(
    stageStream: stageStream,
    service: realCalls
        ? TwilioCallService(fcmToken: fcmService.token)
        : FakeCallService(),
    tokens: realCalls
        ? HttpVoiceTokenService(
            baseUrl: Uri.parse(_serverUrl),
            appToken: _appToken,
          )
        : FakeVoiceTokenService(),
  );
  return AppDependencies(
    buildRole: buildRole,
    onboarding: onboarding,
    pin: pin,
    deviceSetup: const AndroidDeviceSetupService(),
    dialer: const UrlDialerService(),
    buzzer: VibrationBuzzer(),
    share: const SharePlusService(),
    alertPush: push,
    alertNotifier: notifier,
    pause: realCopilot
        ? HttpCopilotPauseService(
            baseUrl: Uri.parse(_serverUrl),
            token: _copilotToken,
          )
        : FakeCopilotPauseService(),
    timeline: realCopilot
        ? HttpTimelineService(
            baseUrl: Uri.parse(_serverUrl),
            token: _copilotToken,
          )
        : FakeTimelineService(),
    call: call,
    callUi: const AndroidCallUiService(),
    stageStream: stageStream,
    attention: ProximityAttentionService(),
    initAlerts: notifier.init,
  );
}

/// Signs in anonymously without holding up startup; a failure is logged and
/// retried by the next `ensureSignedIn`. Debug builds also log the uid and
/// whether an FCM token exists, for checking Firebase on a device.
Future<void> _signIn(AuthService auth, FcmAlertPushService fcm) async {
  try {
    final uid = await auth.ensureSignedIn();
    if (kDebugMode) debugPrint('Jaga uid: $uid');
  } on Object catch (e) {
    debugPrint('Jaga anonymous sign-in failed: $e');
  }
  if (!kDebugMode) return;
  try {
    // Never print the token itself.
    debugPrint(
      'Jaga FCM token ${await fcm.token() == null ? 'missing' : 'ready'}',
    );
  } on Object catch (e) {
    debugPrint('Jaga FCM token failed: ${e.runtimeType}');
  }
}

/// The phone's language when Jaga speaks it: preselected on the first screen.
String _phoneLanguageOr(String fallback) {
  final code = PlatformDispatcher.instance.locale.languageCode;
  return AppLocalizations.supportedLocales.any((l) => l.languageCode == code)
      ? code
      : fallback;
}
