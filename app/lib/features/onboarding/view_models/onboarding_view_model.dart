import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';

import '../../../core/haptics/buzzer.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../data/models/linked_person.dart';
import '../../../data/models/onboarding_progress.dart';
import '../../../data/models/registration.dart';
import '../../../data/repositories/onboarding_repository.dart';
import '../../../data/repositories/pin_repository.dart';
import '../../../data/services/device_setup_service.dart';
import '../../../data/services/dialer_service.dart';
import '../../../data/services/onboarding_api_service.dart';
import '../../../data/services/share_service.dart';

const linkCodeLength = 6;

enum JoinStage { code, names }

/// Drives both setup flows. The repository holds the saved progress; this holds
/// what is typed and checked on the way.
class OnboardingViewModel extends ChangeNotifier with WidgetsBindingObserver {
  OnboardingViewModel({
    required this._repository,
    required this._pin,
    required this._deviceSetup,
    required this._dialer,
    required this._buzzer,
    required this._share,
    String? phoneLanguage,
    this.pollEvery = const Duration(seconds: 5),
  }) : _phoneLanguage =
           phoneLanguage ?? PlatformDispatcher.instance.locale.languageCode {
    _name = progress.personName;
    WidgetsBinding.instance.addObserver(this);
    _enter(progress.step);
  }

  final OnboardingRepository _repository;
  final PinRepository _pin;
  final DeviceSetupService _deviceSetup;
  final DialerService _dialer;
  final Buzzer _buzzer;
  final ShareService _share;
  final String _phoneLanguage;
  final Duration pollEvery;

  bool _disposed = false;
  bool _busy = false;
  bool _networkError = false;
  String _name = '';

  OnboardingProgress get progress => _repository.progress.value;
  OnboardingStep get step => progress.step;
  List<OnboardingStep> get steps => progress.steps;
  int get stepNumber => steps.indexOf(step) + 1;
  int get stepCount => steps.length;
  bool get isFirstStep => step == OnboardingStep.role;

  /// Setting up, or joining: the button shows a spinner.
  bool get busy => _busy;

  /// The server could not be reached on the last try.
  bool get networkError => _networkError;

  // Role: locked once the server knows who this phone is for.
  bool get roleLocked => progress.registration != null || progress.link != null;
  bool get aboutLocked => progress.registration != null;

  /// A linked co-pilot can't return to the link code; the last step of a
  /// protected phone has no back.
  bool get canGoBack =>
      !(progress.link != null && step == OnboardingStep.notifications) &&
      !(progress.role == OnboardingRole.protectedUser &&
          step == OnboardingStep.done);

  bool get canContinue => switch (step) {
    OnboardingStep.role => progress.role != null,
    OnboardingStep.about => aboutLocked || _name.trim().isNotEmpty,
    OnboardingStep.permissions =>
      platformItemsOk(_setup) && (!_xiaomi || _autostartConfirmed),
    OnboardingStep.pin => progress.pinSet,
    OnboardingStep.buzz => _buzzed,
    OnboardingStep.joinCode =>
      _joinStage == JoinStage.code
          ? _code.length == linkCodeLength
          : _yourName.trim().isNotEmpty,
    OnboardingStep.notifications => _setup[SetupItem.notifications] == true,
    _ => true,
  };

  void selectRole(OnboardingRole role) {
    if (roleLocked) return;
    // A co-pilot starts in the phone's language when Jaga speaks it.
    final language = role == OnboardingRole.copilot && _supports(_phoneLanguage)
        ? _phoneLanguage
        : progress.language;
    _repository.update(progress.copyWith(role: role, language: language));
    notifyListeners();
  }

  bool _supports(String code) =>
      AppLocalizations.supportedLocales.any((l) => l.languageCode == code);

  void selectLanguage(String code) {
    _repository.update(progress.copyWith(language: code));
    notifyListeners();
  }

  // About her

  String get name => _name;

  void setName(String value) {
    _name = value;
    notifyListeners();
  }

  Future<bool> _register() async {
    _begin();
    try {
      final registration = await _repository.register(
        personName: _name.trim(),
        commandLanguage: progress.language,
      );
      await _repository.update(
        progress.copyWith(registration: registration, personName: _name.trim()),
      );
      return true;
    } on OnboardingNetworkException {
      _networkError = true;
      return false;
    } finally {
      _end();
    }
  }

  // Phone permissions

  Map<SetupItem, bool> _setup = {};
  bool _xiaomi = false;
  bool _autostartConfirmed = false;

  Map<SetupItem, bool> get setup => _setup;

  /// Xiaomi phones also list autostart, ticked by hand.
  bool get xiaomi => _xiaomi;
  bool get autostartConfirmed => _autostartConfirmed;

  Future<void> refreshSetup() async {
    final state = await _deviceSetup.check();
    final xiaomi = await _deviceSetup.isXiaomi();
    if (_disposed) return;
    _setup = state;
    _xiaomi = xiaomi;
    notifyListeners();
  }

  Future<void> fix(SetupItem item) async {
    await _deviceSetup.fix(item);
    await refreshSetup();
  }

  void confirmAutostart() {
    _autostartConfirmed = true;
    notifyListeners();
  }

  /// Settings pages hand control back here: look again, never trust the last answer.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _checksPermissions(step)) {
      refreshSetup();
    }
  }

  bool _checksPermissions(OnboardingStep s) =>
      s == OnboardingStep.permissions || s == OnboardingStep.notifications;

  // Call forwarding

  Registration get registration => progress.registration!;

  Future<void> dialForwarding() => _dialer.dial(registration.forwardingCode);

  Future<void> checkForwarding() =>
      _dialer.dial(Registration.checkForwardingCode);

  // Co-pilot lock

  String? _firstPin;
  bool _pinMismatch = false;

  /// The second entry is being asked for.
  bool get confirmingPin => _firstPin != null;
  bool get pinMismatch => _pinMismatch;

  Future<void> submitPin(String pin) async {
    final first = _firstPin;
    _pinMismatch = false;
    if (first == null) {
      _firstPin = pin;
    } else if (first != pin) {
      _firstPin = null;
      _pinMismatch = true;
    } else {
      _firstPin = null;
      await _pin.set(pin);
      await _repository.update(progress.copyWith(pinSet: true));
      return next();
    }
    notifyListeners();
  }

  // Link code

  List<String> _joined = const [];
  Timer? _poll;

  /// Co-pilots who have joined, refreshed while the link code is on screen.
  List<String> get joined => _joined;

  Future<void> shareText(String text) => _share.share(text);

  Future<void> refreshJoined() async {
    try {
      final names = await _repository.copilots();
      if (_disposed) return;
      _joined = names;
      notifyListeners();
    } on OnboardingNetworkException {
      // The next poll tries again.
    }
  }

  // Feel the buzz

  bool _buzzed = false;
  bool get buzzed => _buzzed;

  Future<void> playBuzz() async {
    await _buzzer.playOnce();
    _buzzed = true;
    notifyListeners();
  }

  // Co-pilot: join

  JoinStage _joinStage = JoinStage.code;
  String _code = '';
  String _yourName = '';
  String _callName = '';
  JoinError? _joinError;

  JoinStage get joinStage => _joinStage;
  String get code => _code;
  String get yourName => _yourName;

  /// What the co-pilot calls the protected user; prefilled with her name.
  String get callName => _callName;
  JoinError? get joinError => _joinError;

  void setCode(String value) {
    _code = value;
    _joinError = null;
    _networkError = false;
    notifyListeners();
  }

  void setYourName(String value) {
    _yourName = value;
    notifyListeners();
  }

  void setCallName(String value) {
    _callName = value;
    notifyListeners();
  }

  /// Returns true once the co-pilot is linked and the flow may move on.
  Future<bool> _join() async {
    _begin();
    try {
      if (_joinStage == JoinStage.code) {
        _callName = await _repository.checkLinkCode(_code);
        _joinStage = JoinStage.names;
        return false;
      }
      final person = await _repository.join(
        _code,
        copilotName: _yourName.trim(),
      );
      final nickname = _callName.trim();
      await _repository.update(
        progress.copyWith(
          link: LinkedPerson(
            name: nickname.isEmpty ? person.name : nickname,
            phoneNumber: person.phoneNumber,
          ),
        ),
      );
      return true;
    } on JoinException catch (e) {
      _joinError = e.error;
      return false;
    } on OnboardingNetworkException {
      _networkError = true;
      return false;
    } finally {
      _end();
    }
  }

  // Moving between steps

  /// The primary button: does this step's work, then moves on if it succeeded.
  Future<void> next() async {
    if (_busy) return;
    switch (step) {
      case OnboardingStep.about:
        if (!aboutLocked && !await _register()) return;
      case OnboardingStep.joinCode:
        if (!await _join()) return;
      case OnboardingStep.done:
        return _repository.update(progress.copyWith(complete: true));
      default:
    }
    _goTo(steps[steps.indexOf(step) + 1]);
  }

  /// Goes to the previous step. False on the first step: the app should close.
  bool back() {
    if (isFirstStep) return false;
    if (canGoBack) _goTo(steps[steps.indexOf(step) - 1]);
    return true;
  }

  void _goTo(OnboardingStep to) {
    _poll?.cancel();
    _repository.update(progress.copyWith(step: to));
    _enter(to);
    notifyListeners();
  }

  void _enter(OnboardingStep s) {
    if (_checksPermissions(s)) refreshSetup();
    if (s == OnboardingStep.linkCode) {
      refreshJoined();
      _poll = Timer.periodic(pollEvery, (_) => refreshJoined());
    }
  }

  void _begin() {
    _busy = true;
    _networkError = false;
    _joinError = null;
    notifyListeners();
  }

  void _end() {
    _busy = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _poll?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
