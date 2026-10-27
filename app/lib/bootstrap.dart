import 'package:flutter/widgets.dart';

import 'app.dart';
import 'core/haptics/vibration_buzzer.dart';
import 'data/repositories/onboarding_repository.dart';
import 'data/repositories/pin_repository.dart';
import 'data/services/alert_notifier.dart';
import 'data/services/alert_push_service.dart';
import 'data/services/device_setup_service.dart';
import 'data/services/dialer_service.dart';
import 'data/services/key_value_store.dart';
import 'data/services/onboarding_api_service.dart';
import 'data/services/share_service.dart';

/// The real services. The server and push services are still the fakes: no
/// contract and no Firebase project yet.
Future<AppDependencies> createDependencies() async {
  final pin = PinRepository(store: const SecureStore());
  final onboarding = await OnboardingRepository.load(
    store: PreferencesStore(),
    api: FakeOnboardingApiService(),
    pin: pin,
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
