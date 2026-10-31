import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';

import 'app.dart';
import 'core/haptics/vibration_buzzer.dart';
import 'core/l10n/gen/app_localizations.dart';
import 'data/repositories/onboarding_repository.dart';
import 'data/repositories/pin_repository.dart';
import 'data/services/alert_notifier.dart';
import 'data/services/alert_push_service.dart';
import 'data/services/device_setup_service.dart';
import 'data/services/dialer_service.dart';
import 'data/services/key_value_store.dart';
import 'data/services/onboarding_api_service.dart';
import 'data/services/share_service.dart';

/// The real services, except the server and push, which are still Fakes.
Future<AppDependencies> createDependencies() async {
  // TODO(#1): the real onboarding API and push services replace these Fakes once
  // contracts v1 and the Firebase project land.
  debugPrint('Jaga is running on Fake onboarding API and push services.');
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
    alertPush: FakeAlertPushService(),
    alertNotifier: notifier,
    initAlerts: notifier.init,
  );
}

/// The phone's language when Jaga speaks it: preselected on the first screen.
String _phoneLanguageOr(String fallback) {
  final code = PlatformDispatcher.instance.locale.languageCode;
  return AppLocalizations.supportedLocales.any((l) => l.languageCode == code)
      ? code
      : fallback;
}
