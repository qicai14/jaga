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
  testWidgets('a fresh install starts at step 1 in Malay', (tester) async {
    await pumpApp(tester);
    expect(find.text('Telefon ini untuk siapa?'), findsOneWidget);
  });

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
    expect(find.text("You'll get alerts about Mak Cik."), findsOneWidget);
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
