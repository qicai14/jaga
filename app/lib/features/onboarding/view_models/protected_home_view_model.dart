import 'package:flutter/widgets.dart';

import '../../../data/models/registration.dart';
import '../../../data/repositories/onboarding_repository.dart';
import '../../../data/repositories/pin_repository.dart';
import '../../../data/services/device_setup_service.dart';
import '../../../data/services/dialer_service.dart';
import '../../../data/services/onboarding_api_service.dart';
import '../../../data/services/share_service.dart';

/// The protected user's status screen and the settings behind the co-pilot lock.
class ProtectedHomeViewModel extends ChangeNotifier
    with WidgetsBindingObserver {
  ProtectedHomeViewModel({
    required this._repository,
    required this._pin,
    required this._deviceSetup,
    required this._dialer,
    required this._share,
  }) {
    WidgetsBinding.instance.addObserver(this);
    refresh();
  }

  final OnboardingRepository _repository;
  final PinRepository _pin;
  final DeviceSetupService _deviceSetup;
  final DialerService _dialer;
  final ShareService _share;

  bool _disposed = false;
  bool _needsAttention = false;
  List<String> _family = const [];

  /// A step-4 permission is no longer granted: the family must look at the phone.
  bool get needsAttention => _needsAttention;

  /// Names of the family co-pilots who have joined.
  List<String> get family => _family;

  Registration get registration => _repository.progress.value.registration!;
  String get personName => _repository.progress.value.personName;
  String get language => _repository.progress.value.language;

  /// Checks the permissions and the family list. Runs at start and on resume.
  Future<void> refresh() async {
    final attention = !platformItemsOk(await _deviceSetup.check());
    List<String> family;
    try {
      family = await _repository.copilots();
    } on OnboardingNetworkException {
      family = _family;
    }
    if (_disposed) return;
    _needsAttention = attention;
    _family = family;
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  Future<PinResult> verifyPin(String pin) => _pin.verify(pin);

  Future<bool> isLocked() async => await _pin.lockedUntil() != null;

  void selectLanguage(String code) {
    _repository.update(_repository.progress.value.copyWith(language: code));
    notifyListeners();
  }

  Future<void> dialForwarding() => _dialer.dial(registration.forwardingCode);

  Future<void> checkForwarding() =>
      _dialer.dial(Registration.checkForwardingCode);

  Future<void> shareText(String text) => _share.share(text);

  /// Back to step 1; the app swaps to the setup flow.
  Future<void> reset() => _repository.reset();

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
