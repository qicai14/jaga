import 'dart:convert';
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/core/l10n/gen/app_localizations.dart';
import 'package:jaga/data/models/family_alert.dart';
import 'package:jaga/data/models/stage.dart';
import 'package:jaga/data/services/alert_notifier.dart';
import 'package:jaga/debug/fixtures/family_alert_fixtures.dart';

NotificationResponse tap({String? payload, String? actionId}) =>
    NotificationResponse(
      notificationResponseType: actionId == null
          ? NotificationResponseType.selectedNotification
          : NotificationResponseType.selectedNotificationAction,
      payload: payload,
      actionId: actionId,
    );

void main() {
  final l = lookupAppLocalizations(const Locale('en'));
  final money = FamilyAlert.parse(familyMoney);
  final genuine = FamilyAlert.parse(familyMayBeGenuine);

  group('notificationIdFor', () {
    test('is stable and fits in 31 bits', () {
      expect(notificationIdFor('call-1'), notificationIdFor('call-1'));
      for (final id in ['', 'call-1', 'a' * 500, 'ꜩ😀' * 40]) {
        expect(notificationIdFor(id), inInclusiveRange(0, 0x7fffffff));
      }
    });

    test('differs between call ids', () {
      final ids = {for (var i = 0; i < 200; i++) notificationIdFor('call-$i')};
      expect(ids, hasLength(200));
    });
  });

  group('alertContentFor', () {
    test('an alert is loud: family_alerts channel at max importance', () {
      final c = alertContentFor(money, familyPerson, l);
      expect(c.channelId, 'family_alerts');
      expect(c.importance, Importance.max);
      expect(c.id, notificationIdFor('call-1'));
      expect(c.title, 'Mum may be on a scam call');
      expect(c.body, 'Asked to move money. Says they are from PDRM.');
    });

    test('a follow-up is quiet: family_updates channel at low importance', () {
      final c = alertContentFor(genuine, familyPerson, l);
      expect(c.channelId, 'family_updates');
      expect(c.importance, Importance.low);
      expect(c.id, alertContentFor(money, familyPerson, l).id); // replaces it
      expect(c.title, "Mum's call may be genuine");
    });

    test('no agency: the body is only the stage', () {
      final c = alertContentFor(
        FamilyAlert.parse(familyNoAgency),
        familyPerson,
        l,
      );
      expect(c.body, 'Passed to another person.');
    });

    test('the lock screen never shows quotes or the summary', () {
      for (final a in [money, genuine, FamilyAlert.parse(familyLongText)]) {
        final c = alertContentFor(a, familyPerson, l);
        for (final secret in [a.summary, ...a.quotes]) {
          expect(c.title, isNot(contains(secret)));
          expect(c.body, isNot(contains(secret)));
        }
      }
    });
  });

  group('alertOpenFrom', () {
    test('round-trips the alert through the payload', () {
      for (final a in [
        money,
        genuine,
        FamilyAlert.parse(familyNoAgency),
        FamilyAlert.parse(familyNoQuotes),
      ]) {
        final payload = alertContentFor(a, familyPerson, l).payload;
        expect(alertOpenFrom(tap(payload: payload))!.alert, a);
      }
    });

    test('a null agency and an empty summary survive', () {
      final a = FamilyAlert(
        callId: 'c',
        protectedUserName: 'Mum',
        stage: Stage.money,
        summary: '',
        at: DateTime.utc(2026, 10, 27),
        kind: FamilyAlertKind.alert,
      );
      final open = alertOpenFrom(tap(payload: jsonEncode(a.toJson())))!;
      expect(open.alert.claimedAgency, isNull);
      expect(open.alert.summary, '');
    });

    test('autoDial only for the call action', () {
      final payload = alertContentFor(money, familyPerson, l).payload;
      expect(alertOpenFrom(tap(payload: payload))!.autoDial, isFalse);
      expect(
        alertOpenFrom(tap(payload: payload, actionId: 'call'))!.autoDial,
        isTrue,
      );
      expect(
        alertOpenFrom(tap(payload: payload, actionId: 'other'))!.autoDial,
        isFalse,
      );
    });

    test('no payload or a bad one is ignored', () {
      expect(alertOpenFrom(tap()), isNull);
      expect(alertOpenFrom(tap(payload: 'not json')), isNull);
      expect(alertOpenFrom(tap(payload: '{"callId": 1}')), isNull);
    });
  });
}
