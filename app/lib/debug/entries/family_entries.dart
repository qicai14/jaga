import 'package:flutter/material.dart';

import '../../data/models/family_alert.dart';
import '../../data/models/linked_person.dart';
import '../../data/repositories/family_alert_repository.dart';
import '../../data/services/alert_notifier.dart';
import '../../data/services/alert_push_service.dart';
import '../../data/services/dialer_service.dart';
import '../../features/family/view_models/family_alert_view_model.dart';
import '../../features/family/views/family_alert_screen.dart';
import '../fixtures/family_alert_fixtures.dart';
import '../gallery_entry.dart';

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

/// Sends a real notification through [LocalAlertNotifier], to check the
/// heads-up, the lock screen and the Call action on the emulator.
class _NotificationTest extends StatefulWidget {
  const _NotificationTest();

  @override
  State<_NotificationTest> createState() => _NotificationTestState();
}

class _NotificationTestState extends State<_NotificationTest> {
  LocalAlertNotifier? _notifier;

  @override
  void dispose() {
    _notifier?.dispose();
    super.dispose();
  }

  /// Created on the first tap: the plugin only exists on a device.
  Future<void> _send(String raw) async {
    var notifier = _notifier;
    if (notifier == null) {
      notifier = _notifier = LocalAlertNotifier(
        locale: () => Localizations.localeOf(context),
      );
      await notifier.init();
    }
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
  const GalleryEntry(
    feature: 'family',
    state: 'notification-test',
    build: _notificationTest,
  ),
];

Widget _notificationTest(BuildContext _) => const _NotificationTest();
