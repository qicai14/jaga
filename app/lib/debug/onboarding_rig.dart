import '../app.dart';
import '../core/haptics/fake_buzzer.dart';
import '../data/models/onboarding_progress.dart';
import '../data/repositories/onboarding_repository.dart';
import '../data/repositories/pin_repository.dart';
import '../data/services/alert_notifier.dart';
import '../data/services/alert_push_service.dart';
import '../data/services/device_setup_service.dart';
import '../data/services/dialer_service.dart';
import '../data/services/key_value_store.dart';
import '../data/services/onboarding_api_service.dart';
import '../data/services/share_service.dart';
import '../features/onboarding/view_models/onboarding_view_model.dart';
import '../features/onboarding/view_models/protected_home_view_model.dart';

/// The setup services, all fakes and in memory, for the debug gallery and tests.
/// Nothing here touches a plugin.
class OnboardingRig {
  OnboardingRig._(
    this.api,
    this.device,
    this.notifier,
    this.onboarding,
    this.pin,
  );

  static Future<OnboardingRig> create({
    OnboardingProgress start = const OnboardingProgress(),
    DateTime Function()? clock,
    FakeDeviceSetupService? device,
    AlertOpen? launch,
  }) async {
    final api = FakeOnboardingApiService();
    final secrets = InMemoryStore();
    final pin = PinRepository(store: secrets, clock: clock ?? DateTime.now);
    final repository = await OnboardingRepository.load(
      store: InMemoryStore(),
      api: api,
      pin: pin,
    );
    await repository.update(start);
    return OnboardingRig._(
      api,
      device ?? FakeDeviceSetupService(),
      FakeAlertNotifier(launch: launch),
      repository,
      pin,
    );
  }

  final OnboardingRepository onboarding;
  final PinRepository pin;
  final FakeOnboardingApiService api;
  final FakeDeviceSetupService device;
  final dialer = FakeDialerService();
  final buzzer = FakeBuzzer();
  final share = FakeShareService();
  final push = FakeAlertPushService();
  final FakeAlertNotifier notifier;

  AppDependencies get deps => AppDependencies(
    onboarding: onboarding,
    pin: pin,
    deviceSetup: device,
    dialer: dialer,
    buzzer: buzzer,
    share: share,
    alertPush: push,
    alertNotifier: notifier,
    initAlerts: () async {},
  );

  OnboardingViewModel onboardingViewModel({
    Duration pollEvery = const Duration(seconds: 5),
    String phoneLanguage = 'en',
  }) => OnboardingViewModel(
    repository: onboarding,
    pin: pin,
    deviceSetup: device,
    dialer: dialer,
    buzzer: buzzer,
    share: share,
    phoneLanguage: phoneLanguage,
    pollEvery: pollEvery,
  );

  ProtectedHomeViewModel protectedHomeViewModel() => ProtectedHomeViewModel(
    repository: onboarding,
    pin: pin,
    deviceSetup: device,
    dialer: dialer,
    share: share,
  );

  void dispose() {
    onboarding.dispose();
    push.dispose();
    notifier.dispose();
  }
}
