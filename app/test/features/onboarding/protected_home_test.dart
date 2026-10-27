import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/core/widgets/view_model_host.dart';
import 'package:jaga/data/models/onboarding_progress.dart';
import 'package:jaga/data/services/device_setup_service.dart';
import 'package:jaga/data/services/onboarding_api_service.dart';
import 'package:jaga/debug/onboarding_rig.dart';
import 'package:jaga/features/onboarding/view_models/protected_home_view_model.dart';
import 'package:jaga/features/onboarding/views/protected_home_screen.dart';
import 'package:jaga/features/onboarding/views/protected_settings_screen.dart';

import '../../support/harness.dart';

const _done = OnboardingProgress(
  role: OnboardingRole.protectedUser,
  personName: 'Mak Cik Aminah',
  registration: fakeRegistration,
  pinSet: true,
  complete: true,
);

FakeDeviceSetupService _granted() =>
    FakeDeviceSetupService(state: {for (final i in platformItems) i: true});

Future<OnboardingRig> pumpHome(
  WidgetTester tester, {
  double scale = 1.0,
  FakeDeviceSetupService? device,
  List<String> family = const [],
}) async {
  final rig = await OnboardingRig.create(
    start: _done,
    device: device ?? _granted(),
  );
  rig.api.joined = family;
  await rig.pin.set('1234');
  addTearDown(rig.dispose);
  await pumpJaga(
    tester,
    ViewModelHost<ProtectedHomeViewModel>(
      create: rig.protectedHomeViewModel,
      builder: (_, vm) => ProtectedHomeScreen(vm: vm),
    ),
    scale: scale,
  );
  return rig;
}

Future<void> unlockWith(WidgetTester tester, String pin) async {
  for (final d in pin.split('')) {
    await tester.tap(find.text(d));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

Future<void> openGate(WidgetTester tester) async {
  await tester.longPress(find.text('Jaga is protecting you'));
  await tester.pumpAndSettle();
}

/// Text inside the settings route (the status screen below holds some too).
Finder inSettings(String text) => find.descendant(
  of: find.byType(ProtectedSettingsScreen),
  matching: find.text(text),
);

Future<void> scrollSettingsTo(WidgetTester tester, Finder target) =>
    tester.scrollUntilVisible(
      target,
      300,
      // The screen's own scroll view comes first; selectable text has scrollables too.
      scrollable: find
          .descendant(
            of: find.byType(ProtectedSettingsScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );

void main() {
  forEachScale('status shows the check, the headline and who is watching', (
    tester,
    scale,
  ) async {
    await pumpHome(tester, scale: scale, family: ['Aisyah', 'Daniel']);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.text('Jaga is protecting you'), findsOneWidget);
    expect(find.text('Your family'), findsOneWidget);
    expect(find.text('Aisyah, Daniel'), findsOneWidget);
  });

  forEachScale('status with no family says so', (tester, scale) async {
    await pumpHome(tester, scale: scale);
    expect(find.text('No family linked yet'), findsOneWidget);
  });

  forEachScale(
    'a switched-off permission turns the status amber and asks for family',
    (tester, scale) async {
      await pumpHome(tester, scale: scale, device: FakeDeviceSetupService());
      expect(find.text('Ask your family to check Jaga'), findsOneWidget);
      expect(find.text('Jaga is protecting you'), findsNothing);
      expect(find.byIcon(Icons.check_circle), findsNothing);
    },
  );

  testWidgets(
    'the status goes amber when a permission is revoked, and back when fixed',
    (tester) async {
      final rig = await pumpHome(tester);
      expect(find.text('Jaga is protecting you'), findsOneWidget);

      rig.device.state[SetupItem.microphone] = false;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Ask your family to check Jaga'), findsOneWidget);

      rig.device.state[SetupItem.microphone] = true;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Jaga is protecting you'), findsOneWidget);
    },
  );

  forEachScale('a long press asks for the co-pilot lock', (
    tester,
    scale,
  ) async {
    await pumpHome(tester, scale: scale);
    await openGate(tester);
    expect(find.text('Enter the co-pilot lock'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Enter the co-pilot lock'), findsNothing);
  });

  testWidgets('a short tap does nothing', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.text('Jaga is protecting you'));
    await tester.pumpAndSettle();
    expect(find.text('Enter the co-pilot lock'), findsNothing);
  });

  testWidgets('five wrong tries lock it, and the right PIN no longer works', (
    tester,
  ) async {
    await pumpHome(tester);
    await openGate(tester);
    await unlockWith(tester, '1111');
    expect(find.text('Wrong PIN'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await unlockWith(tester, '1111');
    }
    expect(find.text('Wrong PIN'), findsOneWidget);
    await unlockWith(tester, '1111');
    expect(find.text('Too many tries. Wait 5 minutes.'), findsOneWidget);
    expect(find.text('Wrong PIN'), findsNothing);

    await tester.tap(find.text('1'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsNothing);
  });

  testWidgets('the sheet says so at once when it is opened while locked', (
    tester,
  ) async {
    final rig = await OnboardingRig.create(start: _done, device: _granted());
    addTearDown(rig.dispose);
    await rig.pin.set('1234');
    for (var i = 0; i < 5; i++) {
      await rig.pin.verify('0000');
    }
    await pumpJaga(
      tester,
      ViewModelHost<ProtectedHomeViewModel>(
        create: rig.protectedHomeViewModel,
        builder: (_, vm) => ProtectedHomeScreen(vm: vm),
      ),
    );
    await openGate(tester);
    expect(find.text('Too many tries. Wait 5 minutes.'), findsOneWidget);
  });

  testWidgets('the right PIN opens settings, and back returns to the status', (
    tester,
  ) async {
    await pumpHome(tester, family: ['Aisyah']);
    await openGate(tester);
    await unlockWith(tester, '1234');
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Hold to reset Jaga'), findsWidgets);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Jaga is protecting you'), findsOneWidget);
  });

  forEachScale(
    'settings lists language, forwarding, pause token and link code',
    (tester, scale) async {
      await pumpHome(tester, scale: scale, family: ['Aisyah']);
      await openGate(tester);
      await unlockWith(tester, '1234');
      for (final text in [
        'Which language should warnings use?',
        'Forward calls to Jaga',
        '*21*+15550100199#',
        'Pause token',
        'JAGA 7Q4M 2KXP 9D3F',
        'Link code',
        '482 913',
        'Aisyah',
      ]) {
        await scrollSettingsTo(tester, inSettings(text));
        expect(inSettings(text), findsOneWidget, reason: text);
      }
      await scrollSettingsTo(tester, inSettings('Hold to reset Jaga'));
    },
  );

  testWidgets('holding reset forgets the setup and returns to step 1', (
    tester,
  ) async {
    final rig = await pumpHome(tester);
    await openGate(tester);
    await unlockWith(tester, '1234');
    await scrollSettingsTo(tester, inSettings('Hold to reset Jaga'));
    final hold = await tester.startGesture(
      tester.getCenter(find.text('Hold to reset Jaga')),
    );
    await tester.pump(); // the ticker starts on the first frame
    await tester.pump(const Duration(seconds: 3));
    await hold.up();
    await tester.pumpAndSettle();
    expect(rig.onboarding.progress.value.role, isNull);
    expect(rig.onboarding.progress.value.complete, isFalse);
    expect(find.text('Settings'), findsNothing);
  });
}
