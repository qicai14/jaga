import 'dart:convert';
import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/bootstrap.dart';
import 'package:jaga/data/models/linked_person.dart';
import 'package:jaga/data/models/onboarding_progress.dart';
import 'package:jaga/data/repositories/onboarding_repository.dart';
import 'package:jaga/data/services/alert_notifier.dart';
import 'package:jaga/data/services/fcm_alert_push_service.dart';
import 'package:jaga/data/services/key_value_store.dart';
import 'package:jaga/debug/fixtures/family_alert_fixtures.dart';

void main() {
  group('familyAlertFromData', () {
    test('parses the alert JSON string', () {
      final alert = familyAlertFromData({familyAlertDataKey: familyMoney});
      expect(alert?.callId, 'call-1');
    });

    test('drops a missing key, a non-string, bad JSON and a bad stage', () {
      expect(familyAlertFromData({}), isNull);
      expect(familyAlertFromData({familyAlertDataKey: 5}), isNull);
      expect(familyAlertFromData({familyAlertDataKey: '{nope'}), isNull);
      final noStage = (jsonDecode(familyMoney) as Map)..['stage'] = 'none';
      expect(
        familyAlertFromData({familyAlertDataKey: jsonEncode(noStage)}),
        isNull,
      );
    });
  });

  group('showBackgroundAlert', () {
    late FakeAlertNotifier notifier;
    Locale? locale;
    Future<AlertNotifier> create(Locale l) async {
      locale = l;
      return notifier;
    }

    setUp(() {
      notifier = FakeAlertNotifier();
      locale = null;
    });

    Future<void> run(KeyValueStore store, [String payload = familyMoney]) =>
        showBackgroundAlert(
          {familyAlertDataKey: payload},
          store,
          createNotifier: create,
        );

    test('a linked person gets the notification in her language', () async {
      await run(
        InMemoryStore()
          ..values[onboardingProgressKey] = const OnboardingProgress(
            language: 'zh',
            link: LinkedPerson(name: 'Mum'),
          ).toJson(),
      );
      expect(notifier.shown, hasLength(1));
      expect(notifier.shown.single.$1.callId, 'call-1');
      expect(notifier.shown.single.$2.name, 'Mum');
      expect(locale, const Locale('zh'));
    });

    test('no link: nothing is shown', () async {
      await run(
        InMemoryStore()
          ..values[onboardingProgressKey] = const OnboardingProgress().toJson(),
      );
      expect(notifier.shown, isEmpty);
    });

    test('unreadable progress: nothing is shown', () async {
      await run(InMemoryStore()..values[onboardingProgressKey] = 'garbage');
      expect(notifier.shown, isEmpty);
    });

    test('a bad payload is dropped before the store is read', () async {
      await run(_ThrowingStore(), 'x');
      expect(notifier.shown, isEmpty);
    });
  });

  group('initFirebase', () {
    test('is true when init succeeds', () async {
      expect(await initFirebase(() async {}), isTrue);
    });

    test('is false, not a crash, when init fails', () async {
      expect(
        await initFirebase(() async => throw Exception('offline')),
        isFalse,
      );
    });
  });
}

class _ThrowingStore extends InMemoryStore {
  @override
  Future<String?> read(String key) => throw StateError('should not be read');
}
