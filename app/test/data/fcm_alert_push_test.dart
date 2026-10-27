import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/bootstrap.dart';
import 'package:jaga/data/models/onboarding_progress.dart';
import 'package:jaga/data/repositories/onboarding_repository.dart';
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
    test('without a linked person nothing is read or shown', () async {
      // No link: returns before any notification plugin is touched.
      final store = InMemoryStore();
      await showBackgroundAlert({familyAlertDataKey: familyMoney}, store);
      store.values[onboardingProgressKey] = const OnboardingProgress().toJson();
      await showBackgroundAlert({familyAlertDataKey: familyMoney}, store);
    });

    test('a bad payload is dropped before the store is read', () async {
      await showBackgroundAlert({familyAlertDataKey: 'x'}, _ThrowingStore());
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
