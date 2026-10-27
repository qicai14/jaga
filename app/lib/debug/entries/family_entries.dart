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

/// Shows [alert] on a fresh view model backed by fakes.
class _FamilyAlertDemo extends StatefulWidget {
  const _FamilyAlertDemo(this.alert, this.person);

  final FamilyAlert alert;
  final LinkedPerson person;

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
  Widget build(BuildContext context) => FamilyAlertScreen(vm: _vm);
}

GalleryEntry _entry(
  String state,
  String raw, [
  LinkedPerson person = familyPerson,
]) => GalleryEntry(
  feature: 'family',
  state: state,
  build: (_) => _FamilyAlertDemo(FamilyAlert.parse(raw), person),
);

List<GalleryEntry> familyEntries() => [
  _entry('alert-isolation', familyIsolation),
  _entry('alert-money', familyMoney),
  _entry('alert-credentials', familyCredentials),
  _entry('alert-no-agency', familyNoAgency),
  _entry('alert-no-quotes', familyNoQuotes),
  _entry('alert-long-text', familyLongText, familyPersonLongName),
  _entry('alert-no-number', familyIsolation, familyPersonNoNumber),
  _entry('may-be-genuine', familyMayBeGenuine),
];
