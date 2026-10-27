import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/widgets/view_model_host.dart';
import '../../data/models/family_alert.dart';
import '../../data/models/onboarding_progress.dart';
import '../../data/models/linked_person.dart';
import '../../data/repositories/family_alert_repository.dart';
import '../../data/services/alert_notifier.dart';
import '../../data/services/alert_push_service.dart';
import '../../data/services/copilot_pause_service.dart';
import '../../data/services/dialer_service.dart';
import '../../data/services/timeline_service.dart';
import '../../features/family/view_models/clear_pause_view_model.dart';
import '../../features/family/view_models/copilot_home_view_model.dart';
import '../../features/family/view_models/copilot_settings_view_model.dart';
import '../../features/family/view_models/family_alert_view_model.dart';
import '../../features/family/view_models/stage_timeline_view_model.dart';
import '../../features/family/views/copilot_home_screen.dart';
import '../../features/family/views/copilot_settings_screen.dart';
import '../../features/family/views/family_alert_screen.dart';
import '../../features/family/views/stage_timeline_screen.dart';
import '../../features/family/views/widgets/clear_pause_sheet.dart';
import '../fixtures/family_alert_fixtures.dart';
import '../fixtures/timeline_fixtures.dart';
import '../gallery_entry.dart';
import '../onboarding_rig.dart';

/// Shows [alert] on a fresh view model backed by fakes. With a [followUp], a
/// debug bar under the screen pushes it, to watch the band swap in place.
class _FamilyAlertDemo extends StatefulWidget {
  const _FamilyAlertDemo(this.alert, this.person, {this.followUp});

  final FamilyAlert alert;
  final LinkedPerson person;
  final FamilyAlert? followUp;

  @override
  State<_FamilyAlertDemo> createState() => _FamilyAlertDemoState();
}

class _FamilyAlertDemoState extends State<_FamilyAlertDemo> {
  final _push = FakeAlertPushService();
  final _notifier = FakeAlertNotifier();
  late final _repository = FamilyAlertRepository(
    push: _push,
    notifier: _notifier,
    person: widget.person,
  );
  late final _vm = FamilyAlertViewModel(
    repository: _repository,
    dialer: FakeDialerService(),
    initial: widget.alert,
  );

  @override
  void dispose() {
    _vm.dispose();
    _repository.dispose();
    _push.dispose();
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final followUp = widget.followUp;
    final screen = FamilyAlertScreen(vm: _vm);
    if (followUp == null) return screen;
    return Column(
      children: [
        Expanded(child: screen),
        Material(
          child: TextButton(
            onPressed: () => _push.emit(followUp),
            child: const Text('Debug: send the "may be genuine" follow-up'),
          ),
        ),
      ],
    );
  }
}

/// An alert opened from a notification: the screen on a real dialer, so the
/// Call action can be followed by hand all the way to the phone app.
class _OpenedAlert extends StatefulWidget {
  const _OpenedAlert(this.open);

  final AlertOpen open;

  @override
  State<_OpenedAlert> createState() => _OpenedAlertState();
}

class _OpenedAlertState extends State<_OpenedAlert> {
  final _push = FakeAlertPushService();
  late final _repository = FamilyAlertRepository(
    push: _push,
    notifier: FakeAlertNotifier(),
    person: familyPerson,
  );
  late final _vm = FamilyAlertViewModel(
    repository: _repository,
    dialer: const UrlDialerService(),
    initial: widget.open.alert,
  );

  @override
  void dispose() {
    _vm.dispose();
    _repository.dispose();
    _push.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FamilyAlertScreen(vm: _vm, autoDial: widget.open.autoDial);
}

/// Sends a real notification through [LocalAlertNotifier], to check the
/// heads-up, the lock screen and the Call action on the emulator. Opening the
/// notification, or its Call action, shows the alert screen.
class _NotificationTest extends StatefulWidget {
  const _NotificationTest();

  @override
  State<_NotificationTest> createState() => _NotificationTestState();
}

class _NotificationTestState extends State<_NotificationTest> {
  LocalAlertNotifier? _notifier;
  StreamSubscription<AlertOpen>? _opens;

  @override
  void initState() {
    super.initState();
    // Ready before the first tap, so a notification from an earlier run that
    // relaunches the app is routed too. Off a device there is no plugin.
    unawaited(_ready().then<void>((_) {}, onError: _noPlugin));
  }

  void _noPlugin(Object e) => debugPrint('No notifications here: $e');

  @override
  void dispose() {
    _opens?.cancel();
    _notifier?.dispose();
    super.dispose();
  }

  Future<LocalAlertNotifier> _ready() async {
    var notifier = _notifier;
    if (notifier != null) return notifier;
    notifier = _notifier = LocalAlertNotifier(
      locale: () => Localizations.localeOf(context),
    );
    _opens = notifier.opens.listen(_show);
    await notifier.init();
    final launched = await notifier.launchOpen();
    if (launched != null && mounted) _show(launched);
    return notifier;
  }

  void _show(AlertOpen open) {
    if (!mounted) return;
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => _OpenedAlert(open)));
  }

  Future<void> _send(String raw) async {
    final notifier = await _ready();
    await notifier.show(FamilyAlert.parse(raw), familyPerson);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            FilledButton(
              onPressed: () => _send(familyIsolation),
              child: const Text('Send the alert notification'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _send(familyMoney),
              child: const Text('Send the money-stage update (same id)'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _send(familyMayBeGenuine),
              child: const Text('Send the "may be genuine" follow-up'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A co-pilot's setup rig (complete, linked to [familyPerson]) for the
/// screens that need the onboarding repository. Built async, disposed with the demo.
class _WithRig extends StatefulWidget {
  const _WithRig(this.builder);

  final Widget Function(OnboardingRig rig) builder;

  @override
  State<_WithRig> createState() => _WithRigState();
}

class _WithRigState extends State<_WithRig> {
  OnboardingRig? _rig;

  @override
  void initState() {
    super.initState();
    OnboardingRig.create(
      start: const OnboardingProgress(
        role: OnboardingRole.copilot,
        step: OnboardingStep.done,
        link: familyPerson,
        complete: true,
      ),
    ).then((rig) {
      if (mounted) {
        setState(() => _rig = rig);
      } else {
        rig.dispose();
      }
    });
  }

  @override
  void dispose() {
    _rig?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rig = _rig;
    return rig == null ? const SizedBox.shrink() : widget.builder(rig);
  }
}

/// The co-pilot home on fakes. Opening a call, the sheet or Settings works as in the app.
class _CopilotHomeDemo extends StatefulWidget {
  const _CopilotHomeDemo({
    this.pauseActive = false,
    this.many = false,
    this.empty = false,
    this.offline = false,
  });

  final bool pauseActive;
  final bool many;
  final bool empty;
  final bool offline;

  @override
  State<_CopilotHomeDemo> createState() => _CopilotHomeDemoState();
}

class _CopilotHomeDemoState extends State<_CopilotHomeDemo> {
  late final _pause = FakeCopilotPauseService(active: widget.pauseActive)
    ..offline = widget.offline;
  late final _timeline =
      (widget.empty
            ? FakeTimelineService()
            : fixtureTimelineService(many: widget.many))
        ..offline = widget.offline;
  final _dialer = FakeDialerService();

  @override
  Widget build(BuildContext context) => _WithRig(
    (rig) => ViewModelHost(
      create: () => CopilotHomeViewModel(
        person: familyPerson,
        pause: _pause,
        timeline: _timeline,
      ),
      builder: (_, vm) => CopilotHomeScreen(
        vm: vm,
        createClearPause: () =>
            ClearPauseViewModel(personName: familyPerson.name, pause: _pause),
        timelineFor: (call) => StageTimelineViewModel(
          call: call,
          timeline: _timeline,
          dialer: _dialer,
        ),
        createSettings: () => CopilotSettingsViewModel(
          repository: rig.onboarding,
          person: familyPerson,
        ),
      ),
    ),
  );
}

/// The co-pilot's settings on a fresh rig.
class _SettingsDemo extends StatelessWidget {
  const _SettingsDemo();

  @override
  Widget build(BuildContext context) => _WithRig(
    (rig) => ViewModelHost(
      create: () => CopilotSettingsViewModel(
        repository: rig.onboarding,
        person: familyPerson,
      ),
      builder: (_, vm) => CopilotSettingsScreen(vm: vm),
    ),
  );
}

/// One call's timeline on fakes.
class _TimelineDemo extends StatelessWidget {
  const _TimelineDemo(this.callId);

  final String callId;

  @override
  Widget build(BuildContext context) => ViewModelHost(
    create: () => StageTimelineViewModel(
      call: fixtureCalls().firstWhere((c) => c.callId == callId),
      timeline: fixtureTimelineService(),
      dialer: FakeDialerService(),
    ),
    builder: (_, vm) => StageTimelineScreen(vm: vm),
  );
}

enum _SheetState { idle, busy, error }

/// The Clear Jaga Pause sheet, driven into [state] on a fake.
class _ClearPauseDemo extends StatefulWidget {
  const _ClearPauseDemo(this.state);

  final _SheetState state;

  @override
  State<_ClearPauseDemo> createState() => _ClearPauseDemoState();
}

class _ClearPauseDemoState extends State<_ClearPauseDemo> {
  final _pause = FakeCopilotPauseService(active: true);
  late final _vm = ClearPauseViewModel(
    personName: familyPerson.name,
    pause: _pause,
  );

  @override
  void initState() {
    super.initState();
    switch (widget.state) {
      case _SheetState.idle:
        break;
      case _SheetState.busy:
        _pause.hold = Completer<void>().future; // never answers
        unawaited(_vm.clear());
      case _SheetState.error:
        _pause.offline = true;
        unawaited(_vm.clear());
    }
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Align(
      alignment: Alignment.bottomCenter,
      child: ClearPauseSheet(vm: _vm),
    ),
  );
}

GalleryEntry _entry(
  String state,
  String raw, {
  LinkedPerson person = familyPerson,
  String? followUp,
}) => GalleryEntry(
  feature: 'family',
  state: state,
  build: (_) => _FamilyAlertDemo(
    FamilyAlert.parse(raw),
    person,
    followUp: followUp == null ? null : FamilyAlert.parse(followUp),
  ),
);

GalleryEntry _home(String state, Widget demo) =>
    GalleryEntry(feature: 'family', state: state, build: (_) => demo);

List<GalleryEntry> familyEntries() => [
  _entry('alert-isolation', familyIsolation),
  _entry('alert-money', familyMoney),
  _entry('alert-credentials', familyCredentials),
  _entry('alert-no-agency', familyNoAgency),
  _entry('alert-no-quotes', familyNoQuotes),
  _entry('alert-long-text', familyLongText, person: familyPersonLongName),
  _entry('alert-no-number', familyIsolation, person: familyPersonNoNumber),
  _entry('may-be-genuine', familyMayBeGenuine),
  _entry('alert-to-genuine', familyMoney, followUp: familyMayBeGenuine),
  _home('home-pause-active', const _CopilotHomeDemo(pauseActive: true)),
  _home('home-no-pause', const _CopilotHomeDemo()),
  _home('home-empty', const _CopilotHomeDemo(empty: true)),
  _home('home-error', const _CopilotHomeDemo(offline: true)),
  _home('home-many', const _CopilotHomeDemo(pauseActive: true, many: true)),
  _home('settings', const _SettingsDemo()),
  _home('timeline', const _TimelineDemo('call-1')),
  _home('timeline-long-quotes', const _TimelineDemo('call-5')),
  _home('clear-pause-idle', const _ClearPauseDemo(_SheetState.idle)),
  _home('clear-pause-busy', const _ClearPauseDemo(_SheetState.busy)),
  _home('clear-pause-error', const _ClearPauseDemo(_SheetState.error)),
  const GalleryEntry(
    feature: 'family',
    state: 'notification-test',
    build: _notificationTest,
  ),
];

Widget _notificationTest(BuildContext _) => const _NotificationTest();
