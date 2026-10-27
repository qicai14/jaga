import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/core/widgets/big_button.dart';
import 'package:jaga/core/widgets/view_model_host.dart';
import 'package:jaga/data/models/linked_person.dart';
import 'package:jaga/data/models/onboarding_progress.dart';
import 'package:jaga/data/services/device_setup_service.dart';
import 'package:jaga/data/services/dialer_service.dart';
import 'package:jaga/data/services/onboarding_api_service.dart';
import 'package:jaga/debug/onboarding_rig.dart';
import 'package:jaga/features/onboarding/view_models/onboarding_view_model.dart';
import 'package:jaga/features/onboarding/views/onboarding_screen.dart';

import '../../support/harness.dart';

const _protected = OnboardingProgress(
  role: OnboardingRole.protectedUser,
  personName: 'Mak Cik Aminah',
  registration: fakeRegistration,
);
const _copilot = OnboardingProgress(
  role: OnboardingRole.copilot,
  link: LinkedPerson(name: 'Mak Cik Aminah'),
);

/// Before the server knows anyone.
const _newProtected = OnboardingProgress(role: OnboardingRole.protectedUser);
const _newCopilot = OnboardingProgress(role: OnboardingRole.copilot);

class SetupRig {
  SetupRig(this.rig, this.vm);

  final OnboardingRig rig;
  final OnboardingViewModel vm;
}

Future<SetupRig> pumpSetup(
  WidgetTester tester,
  OnboardingProgress start, {
  double scale = 1.0,
  FakeDeviceSetupService? device,
}) async {
  final rig = await OnboardingRig.create(start: start, device: device);
  final vm = rig.onboardingViewModel();
  addTearDown(rig.dispose);
  // The host disposes the view model with the tree, before the timer check.
  await pumpJaga(
    tester,
    ViewModelHost(
      key: UniqueKey(),
      create: () => vm,
      builder: (_, vm) => OnboardingScreen(vm: vm),
    ),
    scale: scale,
  );
  return SetupRig(rig, vm);
}

FilledButton continueButton(WidgetTester tester, [String label = 'Continue']) =>
    tester.widget(find.widgetWithText(FilledButton, label));

Future<void> tapDigits(WidgetTester tester, String digits) async {
  for (final d in digits.split('')) {
    await tester.ensureVisible(find.text(d));
    await tester.tap(find.text(d));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

/// Every step: its title, "Step n of m", and a Continue that stays on screen.
void main() {
  final protectedSteps = {
    OnboardingStep.role: 'Who is this phone for?',
    OnboardingStep.language: 'Which language should warnings use?',
    OnboardingStep.about: 'About her',
    OnboardingStep.permissions: 'Phone permissions',
    OnboardingStep.forwarding: 'Forward calls to Jaga',
    OnboardingStep.pin: 'Set the co-pilot lock',
    OnboardingStep.pauseToken: 'Pause token',
    OnboardingStep.linkCode: 'Link code',
    OnboardingStep.buzz: 'Feel the buzz',
    OnboardingStep.done: 'Jaga is set up.',
  };
  final copilotSteps = {
    OnboardingStep.role: 'Who is this phone for?',
    OnboardingStep.language: 'Choose your language',
    OnboardingStep.joinCode: 'Enter the 6-digit code',
    OnboardingStep.notifications: 'Allow alerts',
    OnboardingStep.done: "You'll get alerts about Mak Cik Aminah.",
  };

  void expectPinned(WidgetTester tester) {
    final bottom = tester.getRect(find.byType(BigButton).last).bottom;
    expect(bottom, lessThanOrEqualTo(phoneSize.height));
    expect(find.byType(BigButton), findsWidgets);
  }

  forEachScale('every protected step shows its title and a pinned Continue', (
    tester,
    scale,
  ) async {
    for (final MapEntry(key: step, value: title) in protectedSteps.entries) {
      await pumpSetup(
        tester,
        _protected.copyWith(step: step, role: OnboardingRole.protectedUser),
        scale: scale,
      );
      final n =
          OnboardingStep.of(OnboardingRole.protectedUser).indexOf(step) + 1;
      expect(find.text(title), findsWidgets, reason: '$step title');
      expect(find.text('Step $n of 10'), findsOneWidget, reason: '$step');
      expectPinned(tester);
      expect(tester.takeException(), isNull, reason: '$step');
    }
  });

  forEachScale('every co-pilot step shows its title and a pinned Continue', (
    tester,
    scale,
  ) async {
    for (final MapEntry(key: step, value: title) in copilotSteps.entries) {
      await pumpSetup(tester, _copilot.copyWith(step: step), scale: scale);
      final n = OnboardingStep.of(OnboardingRole.copilot).indexOf(step) + 1;
      expect(find.text(title), findsWidgets, reason: '$step title');
      expect(find.text('Step $n of 5'), findsOneWidget, reason: '$step');
      expectPinned(tester);
      expect(tester.takeException(), isNull, reason: '$step');
    }
  });

  testWidgets(
    'before a role is chosen there is no step count and Continue is off',
    (tester) async {
      await pumpSetup(tester, const OnboardingProgress());
      expect(find.textContaining('Step '), findsNothing);
      expect(continueButton(tester).onPressed, isNull);
      await tester.tap(find.text('A family co-pilot'));
      await tester.pumpAndSettle();
      expect(find.text('Step 1 of 5'), findsOneWidget);
      expect(continueButton(tester).onPressed, isNotNull);
    },
  );

  testWidgets('role is read-only once registered', (tester) async {
    final s = await pumpSetup(
      tester,
      _protected.copyWith(step: OnboardingStep.role),
    );
    await tester.tap(find.text('A family co-pilot'));
    await tester.pumpAndSettle();
    expect(s.vm.progress.role, OnboardingRole.protectedUser);
  });

  testWidgets('choosing a language switches the app language live', (
    tester,
  ) async {
    final s = await pumpSetup(
      tester,
      _protected.copyWith(step: OnboardingStep.language),
    );
    await tester.tap(find.text('Bahasa Melayu'));
    await tester.pumpAndSettle();
    expect(s.rig.onboarding.progress.value.language, 'ms');
  });

  testWidgets('back returns to the previous step with the values kept', (
    tester,
  ) async {
    await pumpSetup(tester, _newProtected.copyWith(step: OnboardingStep.about));
    expect(find.text('Step 3 of 10'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Mak Cik');
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Step 2 of 10'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Mak Cik'), findsOneWidget);
  });

  testWidgets('About: Continue registers, with an inline error and retry', (
    tester,
  ) async {
    final s = await pumpSetup(
      tester,
      _newProtected.copyWith(step: OnboardingStep.about),
    );
    s.rig.api.offline = true;
    expect(
      continueButton(tester).onPressed,
      isNull,
      reason: 'she needs a name',
    );
    await tester.enterText(find.byType(TextField), 'Mak Cik');
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(
      find.text("Can't reach Jaga. Check the internet and try again."),
      findsOneWidget,
    );
    expect(find.text('Step 3 of 10'), findsOneWidget);

    s.rig.api.offline = false;
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Step 4 of 10'), findsOneWidget);
  });

  testWidgets('About shows a spinner and "Setting up…" while registering', (
    tester,
  ) async {
    final s = await pumpSetup(
      tester,
      _newProtected.copyWith(step: OnboardingStep.about),
    );
    s.vm.setName('Mak Cik');
    s.rig.api.hold = Future<void>.delayed(const Duration(seconds: 1));
    s.vm.next();
    await tester.pump();
    expect(find.text('Setting up…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Step 4 of 10'), findsOneWidget);
  });

  group('permissions', () {
    testWidgets('Continue stays off until every item is green', (tester) async {
      final s = await pumpSetup(
        tester,
        _protected.copyWith(step: OnboardingStep.permissions),
      );
      expect(find.widgetWithText(OutlinedButton, 'Fix'), findsNWidgets(3));
      expect(continueButton(tester).onPressed, isNull);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.widgetWithText(OutlinedButton, 'Fix').first);
        await tester.pumpAndSettle();
      }
      expect(find.widgetWithText(OutlinedButton, 'Fix'), findsNothing);
      expect(s.rig.device.fixed, hasLength(3));
      expect(continueButton(tester).onPressed, isNotNull);
    });

    testWidgets('a resume ticks what was switched on in Settings', (
      tester,
    ) async {
      final s = await pumpSetup(
        tester,
        _protected.copyWith(step: OnboardingStep.permissions),
      );
      expect(continueButton(tester).onPressed, isNull);
      s.rig.device.state.updateAll((_, _) => true);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(OutlinedButton, 'Fix'), findsNothing);
      expect(continueButton(tester).onPressed, isNotNull);
    });

    testWidgets('Xiaomi adds an autostart row that is ticked by hand', (
      tester,
    ) async {
      await pumpSetup(
        tester,
        _protected.copyWith(step: OnboardingStep.permissions),
        device: FakeDeviceSetupService(
          xiaomi: true,
          state: {for (final i in platformItems) i: true},
        ),
      );
      expect(find.text('Start automatically'), findsOneWidget);
      expect(continueButton(tester).onPressed, isNull);
      await tester.ensureVisible(find.text("I've done this"));
      await tester.tap(find.text("I've done this"));
      await tester.pumpAndSettle();
      expect(continueButton(tester).onPressed, isNotNull);
    });
  });

  testWidgets('Dial now hands the dialer a code that survives as a URI', (
    tester,
  ) async {
    final s = await pumpSetup(
      tester,
      _protected.copyWith(step: OnboardingStep.forwarding),
    );
    expect(find.text('*21*+15550100199#'), findsOneWidget);
    expect(continueButton(tester, "I've dialled it").onPressed, isNotNull);
    await tester.tap(find.text('Dial now'));
    await tester.tap(find.text('Check forwarding'));
    await tester.pump();
    final uris = s.rig.dialer.dialed.map((n) => telUri(n).toString()).toList();
    expect(uris.first, allOf(endsWith('%23'), contains('*21*')));
    expect(uris.last, 'tel:*%2321%23');
  });

  group('co-pilot lock', () {
    testWidgets('a mismatch returns to the first entry with the error', (
      tester,
    ) async {
      await pumpSetup(tester, _protected.copyWith(step: OnboardingStep.pin));
      await tapDigits(tester, '1234');
      expect(find.text('Enter the PIN again'), findsOneWidget);
      await tapDigits(tester, '1111');
      expect(find.text("The PINs don't match. Set it again."), findsOneWidget);
      expect(find.text('Enter the PIN again'), findsNothing);
      expect(find.text('Step 6 of 10'), findsOneWidget);
    });

    testWidgets('a match stores a hash, not the digits, and moves on', (
      tester,
    ) async {
      final s = await pumpSetup(
        tester,
        _protected.copyWith(step: OnboardingStep.pin),
      );
      await tapDigits(tester, '1234');
      await tapDigits(tester, '1234');
      expect(find.text('Step 7 of 10'), findsOneWidget);
      expect(s.rig.onboarding.progress.value.pinSet, isTrue);
      expect(s.rig.onboarding.progress.value.toJson(), isNot(contains('1234')));
    });

    testWidgets('the delete key removes the last digit', (tester) async {
      await pumpSetup(tester, _protected.copyWith(step: OnboardingStep.pin));
      await tapDigits(tester, '12');
      await tester.ensureVisible(find.byIcon(Icons.backspace_outlined));
      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tapDigits(tester, '345');
      expect(find.text('Enter the PIN again'), findsOneWidget);
    });
  });

  testWidgets('the pause token is shown in groups of four and shared raw', (
    tester,
  ) async {
    final s = await pumpSetup(
      tester,
      _protected.copyWith(step: OnboardingStep.pauseToken),
    );
    expect(find.text('JAGA 7Q4M 2KXP 9D3F'), findsOneWidget);
    await tester.tap(find.text('Share'));
    await tester.pump();
    expect(s.rig.share.shared, ['JAGA-7Q4M-2KXP-9D3F']);
    await tester.tap(find.text('Copy'));
    await tester.pump();
    expect(find.text('Copied'), findsOneWidget);
  });

  group('link code', () {
    testWidgets(
      'is two groups of three, read digit by digit, and shared with the name',
      (tester) async {
        final handle = tester.ensureSemantics();
        final s = await pumpSetup(
          tester,
          _protected.copyWith(step: OnboardingStep.linkCode),
        );
        expect(find.text('482 913'), findsOneWidget);
        expect(find.bySemanticsLabel('4 8 2 9 1 3'), findsOneWidget);
        expect(find.text('No one yet'), findsOneWidget);
        await tester.tap(find.text('Share'));
        await tester.pump();
        expect(
          s.rig.share.shared.single,
          'Open Jaga, choose "A family co-pilot" and enter 482913 to get alerts about Mak Cik Aminah.',
        );
        handle.dispose();
      },
    );

    testWidgets('lists co-pilots as they join, and Continue never waits', (
      tester,
    ) async {
      final s = await pumpSetup(
        tester,
        _protected.copyWith(step: OnboardingStep.linkCode),
      );
      expect(continueButton(tester).onPressed, isNotNull);
      s.rig.api.joined = ['Aisyah', 'Daniel'];
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();
      expect(find.text('Aisyah, Daniel'), findsOneWidget);
    });
  });

  testWidgets('Feel the buzz plays once and then Continue works', (
    tester,
  ) async {
    final s = await pumpSetup(
      tester,
      _protected.copyWith(step: OnboardingStep.buzz),
    );
    expect(continueButton(tester).onPressed, isNull);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Feel the buzz'));
    await tester.pumpAndSettle();
    expect(s.rig.buzzer.calls, ['once']);
    expect(continueButton(tester).onPressed, isNotNull);
  });

  testWidgets(
    'the last protected step has no back arrow and Finish completes setup',
    (tester) async {
      final s = await pumpSetup(
        tester,
        _protected.copyWith(step: OnboardingStep.done),
      );
      expect(find.byIcon(Icons.arrow_back), findsNothing);
      await tester.tap(find.text('Finish'));
      await tester.pumpAndSettle();
      expect(s.rig.onboarding.progress.value.complete, isTrue);
    },
  );

  group('join', () {
    Future<void> enterCode(WidgetTester tester, String code) async {
      await tester.enterText(find.byType(TextField), code);
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
    }

    testWidgets('a full link code explains why, in a live region', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpSetup(
        tester,
        _newCopilot.copyWith(step: OnboardingStep.joinCode),
      );
      await enterCode(tester, '000000');
      const message =
          '3 family co-pilots are already linked. One must unlink before you can join.';
      expect(find.text(message), findsOneWidget);
      expect(
        tester.getSemantics(find.text(message)),
        matchesSemantics(
          label: message,
          isLiveRegion: true,
          textDirection: TextDirection.ltr,
        ),
      );
      handle.dispose();
    });

    testWidgets('expired and wrong codes have their own messages', (
      tester,
    ) async {
      await pumpSetup(
        tester,
        _newCopilot.copyWith(step: OnboardingStep.joinCode),
      );
      await enterCode(tester, '111111');
      expect(
        find.text('This code has expired. Ask for a new one.'),
        findsOneWidget,
      );
      await enterCode(tester, '123456');
      expect(
        find.text("That code doesn't match. Check the 6 digits."),
        findsOneWidget,
      );
    });

    testWidgets('a valid code asks for the names, then links', (tester) async {
      final s = await pumpSetup(
        tester,
        _newCopilot.copyWith(step: OnboardingStep.joinCode),
      );
      await enterCode(tester, fakeLinkCode);
      expect(find.text('A few details'), findsOneWidget);
      expect(
        find.text(fakeProtectedUserName),
        findsOneWidget,
        reason: 'prefilled',
      );
      expect(continueButton(tester).onPressed, isNull);
      await tester.enterText(
        find.widgetWithText(TextField, 'Your name'),
        'Daniel',
      );
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Allow alerts'), findsOneWidget);
      expect(s.rig.onboarding.progress.value.link!.name, fakeProtectedUserName);
    });
  });

  testWidgets('Not now skips the notification permission', (tester) async {
    await pumpSetup(
      tester,
      _copilot.copyWith(step: OnboardingStep.notifications),
    );
    expect(continueButton(tester).onPressed, isNull);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(find.text('Step 5 of 5'), findsOneWidget);
  });

  testWidgets('a linked co-pilot cannot go back to the link code', (
    tester,
  ) async {
    await pumpSetup(
      tester,
      _copilot.copyWith(step: OnboardingStep.notifications),
    );
    expect(find.byIcon(Icons.arrow_back), findsNothing);
  });

  testWidgets('the debug-only Skip passes the forwarding step', (tester) async {
    final s = await pumpSetup(
      tester,
      _protected.copyWith(step: OnboardingStep.forwarding),
    );
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(s.vm.step, OnboardingStep.pin);
  });
}
