import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/data/models/family_alert.dart';
import 'package:jaga/data/models/stage.dart';
import 'package:jaga/data/repositories/family_alert_repository.dart';
import 'package:jaga/data/services/alert_notifier.dart';
import 'package:jaga/data/services/alert_push_service.dart';
import 'package:jaga/debug/fixtures/family_alert_fixtures.dart';

void main() {
  group('FamilyAlert', () {
    test('parses a v0 payload; kind defaults to alert', () {
      final a = FamilyAlert.parse(familyIsolation);
      expect(a.callId, 'call-1');
      expect(a.stage, Stage.isolation);
      expect(a.claimedAgency, 'PDRM');
      expect(a.quotes, hasLength(1));
      expect(a.at, DateTime.utc(2026, 10, 27, 10, 0, 40));
      expect(a.kind, FamilyAlertKind.alert);
    });

    test(
      'null agency and missing quotes are fine; kind mayBeGenuine parses',
      () {
        expect(FamilyAlert.parse(familyNoAgency).claimedAgency, isNull);
        expect(FamilyAlert.parse(familyNoQuotes).quotes, isEmpty);
        expect(
          FamilyAlert.parse(familyMayBeGenuine).kind,
          FamilyAlertKind.mayBeGenuine,
        );
      },
    );

    test('unknown stage or kind throws (contract drift)', () {
      expect(
        () => FamilyAlert.parse(familyIsolation.replaceAll('isolation', 'x')),
        throwsStateError,
      );
      expect(
        () => FamilyAlert.parse(
          familyMayBeGenuine.replaceAll('mayBeGenuine', 'x'),
        ),
        throwsStateError,
      );
    });

    test('toJson round-trips through parse', () {
      final a = FamilyAlert.parse(familyMayBeGenuine);
      final b = FamilyAlert.fromJson(a.toJson());
      expect(b.callId, a.callId);
      expect(b.kind, a.kind);
      expect(b.stage, a.stage);
      expect(b.at, a.at);
      expect(b.quotes, a.quotes);
    });
  });

  group('FamilyAlertRepository', () {
    late FakeAlertPushService push;
    late FakeAlertNotifier notifier;
    late FamilyAlertRepository repo;

    setUp(() {
      push = FakeAlertPushService();
      notifier = FakeAlertNotifier();
      repo = FamilyAlertRepository(
        push: push,
        notifier: notifier,
        person: familyPerson,
      );
    });
    tearDown(() {
      repo.dispose();
      push.dispose();
      notifier.dispose();
    });

    test('one notification per push, replacing by call id', () {
      push.emit(FamilyAlert.parse(familyIsolation));
      push.emit(FamilyAlert.parse(familyMoney));
      push.emit(FamilyAlert.parse(familyCredentials));
      expect(notifier.shown, hasLength(3));
      expect(
        notificationIdFor(notifier.shown[0].$1.callId),
        notificationIdFor(notifier.shown[1].$1.callId),
      );
      expect(notificationIdFor('call-1'), isNot(notificationIdFor('call-2')));
      expect(notifier.shown.every((s) => s.$2 == familyPerson), isTrue);
    });

    test('the follow-up goes to the quiet channel, alerts to the loud one', () {
      expect(channelIdFor(FamilyAlertKind.alert), alertChannelId);
      expect(channelIdFor(FamilyAlertKind.mayBeGenuine), updateChannelId);
    });

    test('the stage only rises; the kind can become mayBeGenuine', () {
      final alerts = <FamilyAlert>[];
      repo.alerts.listen(alerts.add);
      push.emit(FamilyAlert.parse(familyMoney));
      push.emit(FamilyAlert.parse(familyIsolation)); // late and older
      expect(alerts.last.stage, Stage.money);
      expect(alerts.last.summary, FamilyAlert.parse(familyMoney).summary);

      push.emit(FamilyAlert.parse(familyMayBeGenuine));
      expect(alerts.last.kind, FamilyAlertKind.mayBeGenuine);
      expect(alerts.last.stage, Stage.money);
    });

    test('a newer push for another call is kept separate', () {
      final alerts = <FamilyAlert>[];
      repo.alerts.listen(alerts.add);
      push.emit(FamilyAlert.parse(familyMoney));
      push.emit(FamilyAlert.parse(familyNoAgency));
      expect(alerts.last.callId, 'call-3');
      expect(alerts.last.stage, Stage.handoff);
    });
  });
}
