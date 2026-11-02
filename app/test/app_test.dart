import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/app.dart';
import 'package:jaga/data/models/linked_person.dart';
import 'package:jaga/data/models/onboarding_progress.dart';
import 'package:jaga/data/services/alert_notifier.dart';
import 'package:jaga/data/services/device_setup_service.dart';
import 'package:jaga/data/services/onboarding_api_service.dart';
import 'package:jaga/debug/fixtures/family_alert_fixtures.dart';
import 'package:jaga/debug/onboarding_rig.dart';
import 'package:jaga/data/models/family_alert.dart';

import 'support/harness.dart';

Future<OnboardingRig> pumpApp(
  WidgetTester tester, {
  OnboardingProgress start = const OnboardingProgress(),
  AlertOpen? launch,
}) async {
  final rig = await OnboardingRig.create(
    start: start,
    launch: launch,
    device: FakeDeviceSetupService(
      state: {for (final i in platformItems) i: true},
    ),
  );
  addTearDown(rig.dispose);
  tester.view.physicalSize = phoneSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(JagaApp(deps: rig.deps));
  await tester.pumpAndSettle();
  return rig;
}

const _protectedDone = OnboardingProgress(
  role: OnboardingRole.protectedUser,
  step: OnboardingStep.done,
  personName: 'Mak Cik Aminah',
  registration: fakeRegistration,
  pinSet: true,
);
const _copilotDone = OnboardingProgress(
  role: OnboardingRole.copilot,
  step: OnboardingStep.done,
  link: LinkedPerson(name: 'Mak Cik', phoneNumber: fakeProtectedUserPhone),
);

void main() {
  testWidgets(
    'a fresh install starts on the language screen, in Malay, with no back arrow',
    (tester) async {
      await pumpApp(tester);
      expect(find.text('Pilih bahasa anda'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    },
  );

  testWidgets('choosing a language switches the whole app at once', (
    tester,
  ) async {
    await pumpApp(
      tester,
      start: const OnboardingProgress(
        role: OnboardingRole.copilot,
        step: OnboardingStep.language,
      ),
    );
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Choose your language'), findsOneWidget);
  });

  testWidgets('setup resumes where it stopped', (tester) async {
    await pumpApp(
      tester,
      start: _protectedDone.copyWith(step: OnboardingStep.pin, language: 'en'),
    );
    expect(find.text('Set the co-pilot lock'), findsOneWidget);
  });

  testWidgets('finishing protected setup lands on the status screen', (
    tester,
  ) async {
    await pumpApp(tester, start: _protectedDone.copyWith(language: 'en'));
    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();
    expect(find.text('Jaga is protecting you'), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('a finished protected phone opens on the status screen', (
    tester,
  ) async {
    await pumpApp(
      tester,
      start: _protectedDone.copyWith(language: 'ms', complete: true),
    );
    expect(find.text('Jaga sedang melindungi anda'), findsOneWidget);
  });

  testWidgets('finishing co-pilot setup lands on the co-pilot home', (
    tester,
  ) async {
    await pumpApp(tester, start: _copilotDone.copyWith(language: 'en'));
    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();
    expect(find.text('Mak Cik'), findsOneWidget);
    expect(find.text('Protected'), findsOneWidget);
  });

  group('co-pilot settings', () {
    Future<void> openSettings(WidgetTester tester) async {
      await tester.tap(find.byType(PopupMenuButton<void>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
    }

    testWidgets('the app language changes at once', (tester) async {
      await pumpApp(
        tester,
        start: _copilotDone.copyWith(language: 'en', complete: true),
      );
      await openSettings(tester);
      await tester.tap(find.text('Bahasa Melayu'));
      await tester.pumpAndSettle();
      expect(find.text('Tetapan'), findsOneWidget);
    });

    testWidgets('unlink asks first, then returns to setup', (tester) async {
      final rig = await pumpApp(
        tester,
        start: _copilotDone.copyWith(language: 'en', complete: true),
      );
      await openSettings(tester);
      await tester.tap(find.text('Remove Mak Cik from this phone'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(rig.onboarding.progress.value.link, isNotNull);

      await tester.tap(find.text('Remove Mak Cik from this phone'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Remove'));
      await tester.pumpAndSettle();
      expect(rig.onboarding.progress.value.link, isNull);
      expect(find.text('Choose your language'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });
  });

  testWidgets('a notification tap opens the family alert for a co-pilot', (
    tester,
  ) async {
    final rig = await pumpApp(
      tester,
      start: _copilotDone.copyWith(language: 'en', complete: true),
    );
    rig.notifier.emitOpen(AlertOpen(FamilyAlert.parse(familyIsolation)));
    await tester.pumpAndSettle();
    expect(find.text('Mak Cik may be on a scam call'), findsOneWidget);
  });

  testWidgets('the home reloads when the alert that was opened is closed', (
    tester,
  ) async {
    final rig = await pumpApp(
      tester,
      start: _copilotDone.copyWith(language: 'en', complete: true),
    );
    rig.notifier.emitOpen(AlertOpen(FamilyAlert.parse(familyIsolation)));
    await tester.pumpAndSettle();
    rig.timeline.offline = true; // the server is down when she comes back
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      find.text("Couldn't load calls. Check your internet."),
      findsOneWidget,
    );
  });

  testWidgets('the tap that launched the app opens the alert too', (
    tester,
  ) async {
    await pumpApp(
      tester,
      start: _copilotDone.copyWith(language: 'en', complete: true),
      launch: AlertOpen(FamilyAlert.parse(familyMoney)),
    );
    expect(find.text('Mak Cik may be on a scam call'), findsOneWidget);
  });
}
