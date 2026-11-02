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
    this.callsAreFake = false,
  }) {
    WidgetsBinding.instance.addObserver(this);
    refresh();
  }

  final OnboardingRepository _repository;
  final PinRepository _pin;
  final DeviceSetupService _deviceSetup;
  final DialerService _dialer;
  final ShareService _share;

  /// A release build without the Jaga line settings: it is not really protecting.
  final bool callsAreFake;

  bool _disposed = false;
  bool _needsAttention = false;
  List<String> _family = const [];
  Map<SetupItem, bool> _setup = {};
  bool _xiaomi = false;
  final _tried = <SetupItem>{};

  /// A step-4 permission is no longer granted: the family must look at the phone.
  bool get needsAttention => _needsAttention || callsAreFake;

  /// Per-permission state for the Settings checklist.
  Map<SetupItem, bool> get setup => _setup;

  /// Xiaomi phones also list autostart, ticked by hand and saved.
  bool get xiaomi => _xiaomi;
  bool get autostartConfirmed => _repository.progress.value.autostartConfirmed;

  /// Items whose Fix was pressed: if still red, the row says what to do next.
  Set<SetupItem> get tried => _tried;

  /// Names of the family co-pilots who have joined.
  List<String> get family => _family;

  Registration get registration => _repository.progress.value.registration!;
  String get personName => _repository.progress.value.personName;
  String get language => _repository.progress.value.language;

  /// Checks the permissions and the family list. Runs at start and on resume.
  Future<void> refresh() async {
    final setup = await _deviceSetup.check();
    var xiaomi = false;
    try {
      xiaomi = await _deviceSetup.isXiaomi();
    } catch (_) {
      // Not knowing the maker must not stop the permission check.
    }
    List<String> family;
    try {
      family = await _repository.copilots();
    } on OnboardingNetworkException {
      family = _family;
    }
    if (_disposed) return;
    _setup = setup;
    _xiaomi = xiaomi;
    _needsAttention = !platformItemsOk(setup);
    _family = family;
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  Future<void> fix(SetupItem item) async {
    _tried.add(item);
    await _deviceSetup.fix(item);
    await refresh();
  }

  void confirmAutostart() {
    _repository.update(
      _repository.progress.value.copyWith(autostartConfirmed: true),
    );
    notifyListeners();
  }

  Future<PinResult> verifyPin(String pin) => _pin.verify(pin);

  /// How long the co-pilot lock still holds, or null if it is open.
  Future<Duration?> lockRemaining() => _pin.lockRemaining();

  void selectLanguage(String code) {
    _repository.update(_repository.progress.value.copyWith(language: code));
    notifyListeners();
  }

  Future<void> dialForwarding() => _dialer.dial(registration.forwardingCode);

  Future<void> turnOffForwarding() =>
      _dialer.dial(Registration.cancelForwardingCode);

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
