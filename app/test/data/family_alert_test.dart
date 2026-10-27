import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/data/models/family_alert.dart';
import 'package:jaga/data/models/stage.dart';
import 'package:jaga/data/repositories/family_alert_repository.dart';
import 'package:jaga/data/services/alert_notifier.dart';
import 'package:jaga/data/services/alert_push_service.dart';
import 'package:jaga/debug/fixtures/family_alert_fixtures.dart';

FamilyAlert alert(String raw) => FamilyAlert.parse(raw);

void main() {
  group('FamilyAlert', () {
    test('parses a v0 payload; kind defaults to alert', () {
      final a = alert(familyIsolation);
      expect(a.callId, 'call-1');
      expect(a.stage, Stage.isolation);
      expect(a.claimedAgency, 'PDRM');
      expect(a.quotes, hasLength(1));
      expect(a.at, DateTime.utc(2026, 10, 27, 10, 0, 40));
      expect(a.kind, FamilyAlertKind.alert);
    });

    test('null agency and missing quotes are fine; mayBeGenuine parses', () {
      expect(alert(familyNoAgency).claimedAgency, isNull);
      expect(alert(familyNoQuotes).quotes, isEmpty);
      expect(alert(familyMayBeGenuine).kind, FamilyAlertKind.mayBeGenuine);
    });

    test('unknown stage or kind throws (contract drift)', () {
      expect(
        () => alert(familyIsolation.replaceAll('isolation', 'x')),
        throwsStateError,
      );
      expect(
        () => alert(familyMayBeGenuine.replaceAll('mayBeGenuine', 'x')),
        throwsStateError,
      );
    });

    test('stage none is rejected: the contract never sends it', () {
      expect(
        () => alert(familyIsolation.replaceAll('isolation', 'none')),
        throwsFormatException,
      );
    });

    test('toJson round-trips through parse', () {
      final a = alert(familyMayBeGenuine);
      expect(FamilyAlert.fromJson(a.toJson()), a);
    });

    test('equal when every field matches, different when one does not', () {
      expect(alert(familyMoney), alert(familyMoney));
      expect(alert(familyMoney).hashCode, alert(familyMoney).hashCode);
      expect(alert(familyMoney), isNot(alert(familyIsolation)));
    });
  });

  group('FamilyAlertRepository', () {
    late FakeAlertPushService push;
    late FakeAlertNotifier notifier;
    late FamilyAlertRepository repo;
    late List<FamilyAlert> alerts;

    void build({Object? showError}) {
      push = FakeAlertPushService();
      notifier = FakeAlertNotifier(showError: showError);
      repo = FamilyAlertRepository(
        push: push,
        notifier: notifier,
        person: familyPerson,
      );
      alerts = [];
      repo.alerts.listen(alerts.add);
    }

    setUp(build);
    tearDown(() {
      repo.dispose();
      push.dispose();
      notifier.dispose();
    });

    test('one notification per changing push, replacing by call id', () async {
      push.emit(alert(familyIsolation));
      push.emit(alert(familyMoney));
      push.emit(alert(familyCredentials));
      await pumpEventQueue();
      expect(notifier.shown, hasLength(3));
      expect(notifier.shown[0].$1.callId, notifier.shown[1].$1.callId);
      expect(notifier.shown.every((s) => s.$2 == familyPerson), isTrue);
    });

    test('a redelivery or a stale push re-notifies nobody', () async {
      push.emit(alert(familyMoney));
      push.emit(alert(familyMoney)); // the same push again
      push.emit(alert(familyIsolation)); // older and lower: changes nothing
      await pumpEventQueue();
      expect(notifier.shown, hasLength(1));
      expect(alerts, hasLength(1));
    });

    test('the stage only rises; the kind can become mayBeGenuine', () async {
      push.emit(alert(familyMoney));
      push.emit(alert(familyMayBeGenuine));
      await pumpEventQueue();
      expect(alerts.last.kind, FamilyAlertKind.mayBeGenuine);
      expect(alerts.last.stage, Stage.money);
    });

    test('an older push with a higher stage still raises the stage', () {
      final held = repo.receive(alert(familyIsolation));
      final stale = alert(
        familyMoney.replaceAll('10:01:40Z', '09:00:00Z'),
      ); // older, but money
      final merged = repo.receive(stale);
      expect(merged.stage, Stage.money);
      expect(merged.at, held.at); // the fields stay the newer alert's
      expect(merged.summary, held.summary);
    });

    test('on an equal timestamp the incoming alert wins', () {
      repo.receive(alert(familyMoney));
      final tie = alert(
        familyMoney.replaceAll('The caller now', 'Updated: the caller now'),
      );
      expect(repo.receive(tie).summary, startsWith('Updated'));
    });

    test('receive returns the identical instance when nothing changed', () {
      final first = repo.receive(alert(familyMoney));
      expect(identical(repo.receive(alert(familyMoney)), first), isTrue);
      expect(identical(repo.receive(alert(familyIsolation)), first), isTrue);
    });

    test('another call is kept separate', () async {
      push.emit(alert(familyMoney));
      push.emit(alert(familyNoAgency));
      await pumpEventQueue();
      expect(alerts.last.callId, 'call-3');
      expect(alerts.last.stage, Stage.handoff);
    });

    test(
      'a notification that fails to show does not stop the stream',
      () async {
        repo.dispose();
        push.dispose();
        notifier.dispose();
        build(showError: StateError('no permission'));
        push.emit(alert(familyIsolation));
        push.emit(alert(familyMoney));
        await pumpEventQueue();
        expect(alerts, hasLength(2));
      },
    );
  });
}
