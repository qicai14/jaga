import 'dart:async';

import 'package:flutter/material.dart';

import 'core/haptics/buzzer.dart';
import 'core/l10n/gen/app_localizations.dart';
import 'core/theme/jaga_theme.dart';
import 'core/widgets/view_model_host.dart';
import 'data/models/linked_person.dart';
import 'data/models/onboarding_progress.dart';
import 'data/repositories/family_alert_repository.dart';
import 'data/repositories/onboarding_repository.dart';
import 'data/repositories/pin_repository.dart';
import 'data/services/alert_notifier.dart';
import 'data/services/alert_push_service.dart';
import 'data/services/device_setup_service.dart';
import 'data/services/dialer_service.dart';
import 'data/services/share_service.dart';
import 'features/family/view_models/family_alert_view_model.dart';
import 'features/family/views/family_alert_screen.dart';
import 'features/onboarding/view_models/onboarding_view_model.dart';
import 'features/onboarding/view_models/protected_home_view_model.dart';
import 'features/onboarding/views/copilot_home_screen.dart';
import 'features/onboarding/views/onboarding_screen.dart';
import 'features/onboarding/views/protected_home_screen.dart';

/// Everything the screens need from outside, built once in `bootstrap.dart`
/// (real) or by a test (fakes).
class AppDependencies {
  const AppDependencies({
    required this.onboarding,
    required this.pin,
    required this.deviceSetup,
    required this.dialer,
    required this.buzzer,
    required this.share,
    required this.alertPush,
    required this.alertNotifier,
    required this.initAlerts,
  });

  final OnboardingRepository onboarding;
  final PinRepository pin;
  final DeviceSetupService deviceSetup;
  final DialerService dialer;
  final Buzzer buzzer;
  final ShareService share;
  final AlertPushService alertPush;
  final AlertNotifier alertNotifier;

  /// Creates the notification channels. Only a co-pilot needs it.
  final Future<void> Function() initAlerts;
}

/// The locale and the home screen both come from the saved setup progress.
class JagaApp extends StatefulWidget {
  const JagaApp({super.key, required this.deps});

  final AppDependencies deps;

  @override
  State<JagaApp> createState() => _JagaAppState();
}

class _JagaAppState extends State<JagaApp> {
  /// Built once per language: a progress change must not rebuild the theme.
  final _themes = <String, ThemeData>{};

  AppDependencies get deps => widget.deps;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<OnboardingProgress>(
      valueListenable: deps.onboarding.progress,
      builder: (context, progress, _) {
        final locale = Locale(progress.language);
        return MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          theme: _themes.putIfAbsent(
            progress.language,
            () => buildJagaTheme(locale),
          ),
          themeMode: ThemeMode.light,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _home(progress),
        );
      },
    );
  }

  Widget _home(OnboardingProgress progress) {
    if (!progress.complete) {
      return ViewModelHost(
        create: () => OnboardingViewModel(
          repository: deps.onboarding,
          pin: deps.pin,
          deviceSetup: deps.deviceSetup,
          dialer: deps.dialer,
          buzzer: deps.buzzer,
          share: deps.share,
        ),
        builder: (_, vm) => OnboardingScreen(vm: vm),
      );
    }
    if (progress.role == OnboardingRole.copilot) {
      return CopilotShell(deps: deps, person: progress.link!);
    }
    return ViewModelHost(
      create: () => ProtectedHomeViewModel(
        repository: deps.onboarding,
        pin: deps.pin,
        deviceSetup: deps.deviceSetup,
        dialer: deps.dialer,
        share: deps.share,
      ),
      builder: (_, vm) => ProtectedHomeScreen(vm: vm),
    );
  }
}

/// The co-pilot side until #23: a placeholder home that opens the family alert
/// when a notification is tapped, including the tap that launched the app.
class CopilotShell extends StatefulWidget {
  const CopilotShell({super.key, required this.deps, required this.person});

  final AppDependencies deps;
  final LinkedPerson person;

  @override
  State<CopilotShell> createState() => _CopilotShellState();
}

class _CopilotShellState extends State<CopilotShell> {
  late final _alerts = FamilyAlertRepository(
    push: widget.deps.alertPush,
    notifier: widget.deps.alertNotifier,
    person: widget.person,
  );
  StreamSubscription<AlertOpen>? _opens;

  @override
  void initState() {
    super.initState();
    unawaited(_listen());
  }

  Future<void> _listen() async {
    final notifier = widget.deps.alertNotifier;
    await widget.deps.initAlerts();
    final launch = await notifier.launchOpen();
    if (!mounted) return;
    _opens = notifier.opens.listen(_open);
    if (launch != null) _open(launch);
  }

  void _open(AlertOpen open) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ViewModelHost(
          create: () => FamilyAlertViewModel(
            repository: _alerts,
            dialer: widget.deps.dialer,
            initial: open.alert,
          ),
          builder: (_, vm) =>
              FamilyAlertScreen(vm: vm, autoDial: open.autoDial),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _opens?.cancel();
    _alerts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      CopilotHomeScreen(personName: widget.person.name);
}
