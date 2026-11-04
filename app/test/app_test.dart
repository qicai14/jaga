import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/app.dart';
import 'package:jaga/core/widgets/hold_to_confirm_button.dart';
import 'package:jaga/data/models/alerted_call.dart';
import 'package:jaga/data/models/stage.dart';
import 'package:jaga/features/family/views/copilot_home_screen.dart';
import 'package:jaga/features/onboarding/views/onboarding_screen.dart';
import 'package:jaga/features/onboarding/views/protected_home_screen.dart';
import 'package:jaga/features/family/views/family_alert_screen.dart';
import 'package:jaga/features/family/views/stage_timeline_screen.dart';
import 'package:jaga/features/family/views/widgets/alerted_call_tile.dart';
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
  double scale = 1.0,
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
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
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

/// What a 10sp text really gets under the system scale of the test (2.0).
double _scaled(WidgetTester tester, Type screen) =>
    MediaQuery.textScalerOf(tester.element(find.byType(screen).first))
        .scale(10);

void main() {
  group('text scale (system x2.0)', () {
    final copilot = _copilotDone.copyWith(language: 'en', complete: true);

    testWidgets('a co-pilot screen and a pushed family alert stop at 1.5', (
      tester,
    ) async {
      final rig = await pumpApp(tester, start: copilot, scale: 2.0);
      expect(_scaled(tester, CopilotHomeScreen), 15);
      rig.notifier.emitOpen(AlertOpen(FamilyAlert.parse(familyMoney)));
      await tester.pumpAndSettle();
      expect(_scaled(tester, FamilyAlertScreen), 15);
    });

    testWidgets('onboarding stops at 1.5', (tester) async {
      await pumpApp(tester, scale: 2.0);
      expect(_scaled(tester, OnboardingScreen), 15);
    });

    testWidgets('the protected home and the routes over it keep 2.0', (
      tester,
    ) async {
      await pumpApp(
        tester,
        start: _protectedDone.copyWith(language: 'en', complete: true),
        scale: 2.0,
      );
      expect(_scaled(tester, ProtectedHomeScreen), 20);
      // The call and Warning screens are routes pushed over this home.
      final context = tester.element(find.byType(ProtectedHomeScreen));
      unawaited(
        Navigator.of(context).push<void>(
          MaterialPageRoute(builder: (_) => const Scaffold(body: Text('over'))),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        MediaQuery.textScalerOf(tester.element(find.text('over'))).scale(10),
        20,
      );
    });
  });

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

  group('co-pilot navigation', () {
    final copilot = _copilotDone.copyWith(language: 'en', complete: true);
    final money = FamilyAlert.parse(familyMoney);

    testWidgets(
      'a launch alert: See what happened, a live timeline, Back, Back',
      (tester) async {
        await pumpApp(tester, start: copilot, launch: AlertOpen(money));
        expect(find.text('Mum may be on a scam call'), findsNothing);
        expect(find.byType(FamilyAlertScreen), findsOneWidget);
        final button = find.text('See what happened');
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(find.byType(StageTimelineScreen), findsOneWidget);
        final delete = tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.delete_outline),
        );
        expect(delete.onPressed, isNull);
        final vm = tester
            .widget<StageTimelineScreen>(find.byType(StageTimelineScreen))
            .vm;
        expect(vm.call.callId, money.callId);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.byType(FamilyAlertScreen), findsOneWidget);
        await tester.ensureVisible(find.byTooltip('Back to home'));
        await tester.tap(find.byTooltip('Back to home'));
        await tester.pumpAndSettle();
        expect(find.byType(CopilotHomeScreen), findsOneWidget);
      },
    );

    testWidgets('a live call with a held alert opens the alert from home', (
      tester,
    ) async {
      final rig = await pumpApp(
        tester,
        start: copilot,
        launch: AlertOpen(money),
      );
      rig.timeline.add(AlertedCall.fromAlert(money));
      await tester.ensureVisible(find.byTooltip('Back to home'));
      await tester.tap(find.byTooltip('Back to home'));
      await tester.pumpAndSettle();
      expect(find.text('Live now'), findsOneWidget);
      await tester.tap(find.byType(AlertedCallTile).first);
      await tester.pumpAndSettle();
      expect(find.byType(FamilyAlertScreen), findsOneWidget);
    });
  });

  group('co-pilot settings', () {
    Future<void> openSettings(WidgetTester tester) async {
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
      expect(
        find.text('Tetapan'),
        findsNWidgets(2),
      ); // the tab and the page title
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
      expect(find.byType(NavigationBar), findsNothing);
    });
  });

  group('co-pilot tabs', () {
    final copilot = _copilotDone.copyWith(language: 'en', complete: true);
    final ended = AlertedCall(
      callId: 'old-1',
      at: DateTime.utc(2026, 10, 20, 9),
      stage: Stage.money,
    );

    /// A rig with one ended call, loaded (an alert opened and closed reloads).
    Future<OnboardingRig> pumpWithCall(WidgetTester tester) async {
      final rig = await pumpApp(tester, start: copilot);
      rig.timeline.add(ended);
      rig.notifier.emitOpen(AlertOpen(FamilyAlert.parse(familyMoney)));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      return rig;
    }

    testWidgets('home has no app bar and no gear; See all calls opens Calls', (
      tester,
    ) async {
      await pumpWithCall(tester);
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Last alert'), findsOneWidget);
      await tester.tap(find.text('See all calls'));
      await tester.pumpAndSettle();
      expect(find.text('Alerted calls'), findsOneWidget);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        1,
      );
    });

    testWidgets('a Calls tile opens the timeline over the bar; Back is Calls', (
      tester,
    ) async {
      await pumpWithCall(tester);
      await tester.tap(find.text('Calls'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(AlertedCallTile).first);
      await tester.pumpAndSettle();
      expect(find.byType(StageTimelineScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Alerted calls'), findsOneWidget);
    });

    testWidgets('a notification on Calls opens the alert without the bar', (
      tester,
    ) async {
      final rig = await pumpApp(tester, start: copilot);
      await tester.tap(find.text('Calls'));
      await tester.pumpAndSettle();
      rig.notifier.emitOpen(AlertOpen(FamilyAlert.parse(familyMoney)));
      await tester.pumpAndSettle();
      expect(find.byType(FamilyAlertScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      await tester.ensureVisible(find.byTooltip('Back to home'));
      await tester.tap(find.byTooltip('Back to home'));
      await tester.pumpAndSettle();
      expect(find.text('Alerted calls'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);

      // System Back closes it the same way.
      rig.notifier.emitOpen(AlertOpen(FamilyAlert.parse(familyMoney)));
      await tester.pumpAndSettle();
      expect(find.byType(FamilyAlertScreen), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(FamilyAlertScreen), findsNothing);
      expect(find.text('Alerted calls'), findsOneWidget);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        1,
      );
    });

    testWidgets('clearing the pause shows one SnackBar, not one per tab', (
      tester,
    ) async {
      final rig = await pumpApp(tester, start: copilot);
      rig.pause.active = true;
      rig.notifier.emitOpen(AlertOpen(FamilyAlert.parse(familyMoney)));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute(); // reloads Home: the card shows
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear Jaga Pause'));
      await tester.pumpAndSettle();
      final g = await tester.startGesture(
        tester.getCenter(find.byType(HoldToConfirmButton)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2100));
      await g.up();
      await tester.pumpAndSettle();
      expect(find.text('Jaga Pause cleared'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('Back on Calls goes to Home first', (tester) async {
      await pumpApp(tester, start: copilot);
      await tester.tap(find.text('Calls'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0,
      );
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
