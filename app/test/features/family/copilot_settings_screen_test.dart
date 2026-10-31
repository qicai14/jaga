import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/data/models/onboarding_progress.dart';
import 'package:jaga/data/repositories/onboarding_repository.dart';
import 'package:jaga/data/repositories/pin_repository.dart';
import 'package:jaga/data/services/key_value_store.dart';
import 'package:jaga/data/services/onboarding_api_service.dart';
import 'package:jaga/debug/fixtures/family_alert_fixtures.dart';
import 'package:jaga/features/family/view_models/copilot_settings_view_model.dart';
import 'package:jaga/features/family/views/copilot_settings_screen.dart';

import '../../support/harness.dart';

/// A store that cannot delete, so unlinking (which resets the lock) fails.
class _StuckStore extends InMemoryStore {
  @override
  Future<void> delete(String key) => throw StateError('stuck');
}

const _linked = OnboardingProgress(
  role: OnboardingRole.copilot,
  step: OnboardingStep.done,
  link: familyPerson,
  complete: true,
  language: 'en',
);

Future<OnboardingRepository> repository({KeyValueStore? pinStore}) async {
  final repo = await OnboardingRepository.load(
    store: InMemoryStore(),
    api: FakeOnboardingApiService(),
    pin: PinRepository(store: pinStore ?? InMemoryStore()),
  );
  await repo.update(_linked);
  addTearDown(repo.dispose);
  return repo;
}

Future<CopilotSettingsViewModel> pump(
  WidgetTester tester,
  double scale, {
  KeyValueStore? pinStore,
  Locale locale = const Locale('en'),
}) async {
  final vm = CopilotSettingsViewModel(
    repository: await repository(pinStore: pinStore),
    person: familyPerson,
  );
  addTearDown(vm.dispose);
  await pumpJaga(
    tester,
    CopilotSettingsScreen(vm: vm),
    scale: scale,
    locale: locale,
  );
  return vm;
}

void main() {
  forEachScale('settings: language list and the remove button', (
    tester,
    scale,
  ) async {
    await pump(tester, scale);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Bahasa Melayu'), findsOneWidget);
    expect(find.text('Remove Mum from this phone'), findsOneWidget);
  });

  for (final locale in const ['ms', 'ta']) {
    testWidgets('settings in $locale at text x2.0 has no overflow', (
      tester,
    ) async {
      await pump(tester, 2.0, locale: Locale(locale));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('removing asks first and wording says it is this phone only', (
    tester,
  ) async {
    final vm = await pump(tester, 1.0);
    await tester.tap(find.text('Remove Mum from this phone'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Remove Mum from this phone? You can link again with a new code.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(vm.language, 'en');
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('a failed removal says so and stays on the screen', (
    tester,
  ) async {
    await pump(tester, 1.0, pinStore: _StuckStore());
    await tester.tap(find.text('Remove Mum from this phone'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Remove'));
    await tester.pumpAndSettle();
    expect(find.text("Couldn't remove Mum. Try again."), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
