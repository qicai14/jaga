import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/data/models/family_alert.dart';
import 'package:jaga/data/models/stage.dart';
import 'package:jaga/data/repositories/family_alert_repository.dart';
import 'package:jaga/data/services/alert_notifier.dart';
import 'package:jaga/data/services/alert_push_service.dart';
import 'package:jaga/data/services/dialer_service.dart';
import 'package:jaga/debug/fixtures/family_alert_fixtures.dart';
import 'package:jaga/features/family/view_models/family_alert_view_model.dart';

void main() {
  late FakeAlertPushService push;
  late FakeAlertNotifier notifier;
  late FakeDialerService dialer;
  late FamilyAlertRepository repo;
  late FamilyAlertViewModel vm;

  void build({required String initial, bool hasNumber = true}) {
    push = FakeAlertPushService();
    notifier = FakeAlertNotifier();
    dialer = FakeDialerService();
    repo = FamilyAlertRepository(
      push: push,
      notifier: notifier,
      person: hasNumber ? familyPerson : familyPersonNoNumber,
    );
    vm = FamilyAlertViewModel(
      repository: repo,
      dialer: dialer,
      initial: FamilyAlert.parse(initial),
    );
  }

  tearDown(() {
    vm.dispose();
    repo.dispose();
    push.dispose();
    notifier.dispose();
  });

  test('starts from the alert in hand; the local nickname wins', () {
    build(initial: familyIsolation);
    expect(vm.state.personName, 'Mum'); // the push said "Mummy"
    expect(vm.state.stage, Stage.isolation);
    expect(vm.state.agency, 'PDRM');
    expect(vm.state.quotes, hasLength(1));
    expect(vm.state.canDial, isTrue);
  });

  test('a push for the same call updates in place and notifies listeners', () {
    build(initial: familyIsolation);
    var notified = 0;
    vm.addListener(() => notified++);
    push.emit(FamilyAlert.parse(familyMoney));
    expect(vm.state.stage, Stage.money);
    expect(vm.state.quotes, hasLength(2));
    expect(notified, 1);
  });

  test('another call is ignored', () {
    build(initial: familyIsolation);
    push.emit(FamilyAlert.parse(familyCredentials));
    expect(vm.state.stage, Stage.isolation);
  });

  test('the follow-up flips the kind, hides quotes, and the stage holds', () {
    build(initial: familyMoney);
    push.emit(FamilyAlert.parse(familyMayBeGenuine));
    expect(vm.state.kind, FamilyAlertKind.mayBeGenuine);
    expect(vm.state.quotes, isEmpty);
    expect(vm.state.stage, Stage.money);
  });

  test('a late older alert does not lower the stage', () {
    build(initial: familyMoney);
    push.emit(FamilyAlert.parse(familyIsolation));
    expect(vm.state.stage, Stage.money);
  });

  test('call dials the known number', () async {
    build(initial: familyIsolation);
    await vm.call();
    expect(dialer.dialed, ['+60 12-345 6789']);
  });

  test('no number: canDial is false and call opens the dialer empty', () async {
    build(initial: familyIsolation, hasNumber: false);
    expect(vm.state.canDial, isFalse);
    await vm.call();
    expect(dialer.dialed, [null]);
  });
}
