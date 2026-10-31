import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/data/models/onboarding_progress.dart';
import 'package:jaga/data/repositories/pin_repository.dart';
import 'package:jaga/data/services/device_setup_service.dart';
import 'package:jaga/data/services/dialer_service.dart';
import 'package:jaga/data/services/onboarding_api_service.dart';
import 'package:jaga/debug/onboarding_rig.dart';
import 'package:jaga/features/onboarding/view_models/onboarding_view_model.dart';

const _protectedAt = OnboardingProgress(role: OnboardingRole.protectedUser);
const _copilotAt = OnboardingProgress(role: OnboardingRole.copilot);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late OnboardingRig rig;
  late OnboardingViewModel vm;

  Future<void> start(
    OnboardingProgress progress, {
    FakeDeviceSetupService? device,
  }) async {
    rig = await OnboardingRig.create(start: progress, device: device);
    vm = rig.onboardingViewModel(pollEvery: const Duration(milliseconds: 20));
    addTearDown(() {
      vm.dispose();
      rig.dispose();
    });
  }

  Future<void> enterPin(String pin) {
    vm.setPinDigits(pin);
    return vm.next();
  }

  Future<void> pump() => Future<void>.delayed(Duration.zero);

  group('protected flow', () {
    test('walks the ten steps in order and saves each one', () async {
      await start(const OnboardingProgress());
      expect(vm.stepCount, 10);
      vm.selectRole(OnboardingRole.protectedUser);
      await vm.next(); // role
      await vm.next(); // language
      expect(vm.step, OnboardingStep.about);
      vm.setName('Mak Cik');
      await vm.next(); // registers
      expect(vm.step, OnboardingStep.permissions);
      expect(rig.onboarding.progress.value.registration, isNotNull);
      for (final item in platformItems) {
        await vm.fix(item);
      }
      await vm.next();
      await vm.next(); // forwarding
      expect(vm.step, OnboardingStep.pin);
      await enterPin('1234');
      await enterPin('1234'); // Continue twice: set, then confirm
      expect(vm.step, OnboardingStep.pauseToken);
      await vm.next();
      await vm.next(); // link code
      expect(vm.step, OnboardingStep.buzz);
      await vm.playBuzz();
      await vm.next();
      expect(vm.step, OnboardingStep.done);
      expect(vm.stepNumber, 10);
      await vm.next();
      expect(rig.onboarding.progress.value.complete, isTrue);
    });

    test(
      'role and language start Malay; selecting a language saves it',
      () async {
        await start(const OnboardingProgress());
        expect(vm.progress.language, 'ms');
        vm.selectLanguage('zh');
        expect(rig.onboarding.progress.value.language, 'zh');
      },
    );

    test(
      'Continue on About needs a name; a failed registration stays put',
      () async {
        await start(_protectedAt.copyWith(step: OnboardingStep.about));
        expect(vm.canContinue, isFalse);
        vm.setName('  ');
        expect(vm.canContinue, isFalse);
        vm.setName('Mak Cik');
        rig.api.offline = true;
        await vm.next();
        expect(vm.step, OnboardingStep.about);
        expect(vm.networkError, isTrue);
        expect(vm.busy, isFalse);

        rig.api.offline = false;
        await vm.next();
        expect(vm.step, OnboardingStep.permissions);
        expect(vm.networkError, isFalse);
        expect(rig.onboarding.progress.value.personName, 'Mak Cik');
      },
    );

    test('shows busy while registering', () async {
      await start(_protectedAt.copyWith(step: OnboardingStep.about));
      vm.setName('Mak Cik');
      final gate = Future<void>.delayed(const Duration(milliseconds: 30));
      rig.api.hold = gate;
      final done = vm.next();
      expect(vm.busy, isTrue);
      await done;
      expect(vm.busy, isFalse);
    });

    test('back keeps values; role and About lock after registration', () async {
      await start(_protectedAt.copyWith(step: OnboardingStep.about));
      vm.setName('Mak Cik');
      expect(vm.back(), isTrue);
      expect(vm.step, OnboardingStep.role);
      await vm.next();
      expect(vm.name, 'Mak Cik');
      expect(vm.roleLocked, isFalse);

      await vm.next(); // registers
      vm.back(); // About
      vm.back(); // role
      expect(vm.step, OnboardingStep.role);
      expect(vm.roleLocked, isTrue);
      expect(vm.aboutLocked, isTrue);
      vm.selectRole(OnboardingRole.copilot);
      expect(vm.progress.role, OnboardingRole.protectedUser);
      vm.back();
      expect(vm.step, OnboardingStep.language);

      await vm.next();
      await vm.next();
      await vm.next(); // About again: no second registration
      expect(vm.step, OnboardingStep.permissions);
    });

    test('back on step 1 asks the app to close', () async {
      await start(const OnboardingProgress());
      expect(vm.back(), isFalse);
      expect(vm.canGoBack, isFalse);
    });

    test('back from Role returns to the language, kept', () async {
      await start(const OnboardingProgress());
      vm.selectLanguage('zh');
      await vm.next();
      expect(vm.step, OnboardingStep.role);
      expect(vm.back(), isTrue);
      expect(vm.step, OnboardingStep.language);
      expect(vm.progress.language, 'zh');
    });

    test('the last step has no back', () async {
      await start(
        _protectedAt.copyWith(
          step: OnboardingStep.done,
          registration: fakeRegistration,
        ),
      );
      expect(vm.canGoBack, isFalse);
    });

    test('resumes at the saved step', () async {
      await start(
        _protectedAt.copyWith(
          step: OnboardingStep.pin,
          registration: fakeRegistration,
        ),
      );
      expect(vm.step, OnboardingStep.pin);
      expect(vm.stepNumber, 6);
    });
  });

  group('permissions', () {
    test(
      'Continue waits for every item; each is checked again, never remembered',
      () async {
        await start(
          _protectedAt.copyWith(step: OnboardingStep.permissions),
          device: FakeDeviceSetupService(
            state: {SetupItem.notifications: true},
          ),
        );
        await pump();
        expect(
          vm.setup[SetupItem.notifications],
          isTrue,
          reason: 'checked on entering the step',
        );
        expect(vm.canContinue, isFalse);

        await vm.fix(SetupItem.microphone);
        expect(vm.canContinue, isFalse);
        await vm.fix(SetupItem.fullScreenAlerts);
        expect(vm.canContinue, isTrue);
        expect(rig.device.fixed, [
          SetupItem.microphone,
          SetupItem.fullScreenAlerts,
        ]);
      },
    );

    test(
      'a permission switched on in Settings ticks when the app resumes',
      () async {
        await start(_protectedAt.copyWith(step: OnboardingStep.permissions));
        await pump();
        expect(vm.canContinue, isFalse);
        rig.device.state.updateAll((_, _) => true);
        vm.didChangeAppLifecycleState(AppLifecycleState.resumed);
        await pump();
        expect(vm.canContinue, isTrue);
      },
    );

    test('on Xiaomi the autostart tick is also needed', () async {
      await start(
        _protectedAt.copyWith(step: OnboardingStep.permissions),
        device: FakeDeviceSetupService(
          xiaomi: true,
          state: {for (final i in platformItems) i: true},
        ),
      );
      await pump();
      expect(vm.xiaomi, isTrue);
      expect(vm.canContinue, isFalse);
      vm.confirmAutostart();
      expect(vm.canContinue, isTrue);
    });

    test('the calling account never blocks Continue', () async {
      await start(
        _protectedAt.copyWith(step: OnboardingStep.permissions),
        device: FakeDeviceSetupService(
          state: {for (final i in platformItems) i: true},
        ),
      );
      await pump();
      expect(vm.setup[SetupItem.callingAccount], isFalse);
      expect(vm.canContinue, isTrue);
    });
  });

  group('forwarding', () {
    test('dials a code that ends in an encoded hash', () async {
      await start(
        _protectedAt.copyWith(
          step: OnboardingStep.forwarding,
          registration: fakeRegistration,
        ),
      );
      await vm.dialForwarding();
      await vm.checkForwarding();
      final dialed = rig.dialer.dialed
          .map((n) => telUri(n).toString())
          .toList();
      expect(dialed.first, 'tel:*21*+15550100199%23');
      expect(dialed.last, 'tel:*%2321%23');
    });
  });

  group('co-pilot lock', () {
    test('a mismatch returns to the first entry with the error', () async {
      await start(
        _protectedAt.copyWith(
          step: OnboardingStep.pin,
          registration: fakeRegistration,
        ),
      );
      expect(vm.canContinue, isFalse);
      await enterPin('1234');
      expect(vm.confirmingPin, isTrue);
      expect(vm.canContinue, isFalse, reason: 'the confirmation starts empty');
      await enterPin('1111');
      expect(vm.confirmingPin, isFalse);
      expect(vm.pinMismatch, isTrue);
      expect(vm.canContinue, isFalse);
      expect(vm.step, OnboardingStep.pin);
      await enterPin('1234');
      expect(vm.pinMismatch, isFalse, reason: 'a fresh entry clears the error');
    });

    test('a match stores the PIN and moves on', () async {
      await start(
        _protectedAt.copyWith(
          step: OnboardingStep.pin,
          registration: fakeRegistration,
        ),
      );
      await enterPin('1234');
      await enterPin('1234');
      expect(rig.onboarding.progress.value.pinSet, isTrue);
      expect(vm.step, OnboardingStep.pauseToken);
      expect(await rig.pin.verify('1234'), PinResult.ok);
    });
  });

  group('link code', () {
    test('lists who joined, polling while the step is open', () async {
      await start(
        _protectedAt.copyWith(
          step: OnboardingStep.linkCode,
          registration: fakeRegistration,
        ),
      );
      await pump();
      expect(vm.joined, isEmpty);
      rig.api.joined = ['Aisyah'];
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(vm.joined, ['Aisyah']);

      await vm.next(); // leaving stops the polling
      rig.api.joined = ['Aisyah', 'Daniel'];
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(vm.joined, ['Aisyah']);
    });

    test('sharing hands the text to the share service', () async {
      await start(
        _protectedAt.copyWith(
          step: OnboardingStep.linkCode,
          registration: fakeRegistration,
        ),
      );
      await vm.shareText('hello');
      expect(rig.share.shared, ['hello']);
    });
  });

  group('buzz', () {
    test('Continue needs one play', () async {
      await start(
        _protectedAt.copyWith(
          step: OnboardingStep.buzz,
          registration: fakeRegistration,
        ),
      );
      expect(vm.canContinue, isFalse);
      await vm.playBuzz();
      expect(rig.buzzer.calls, ['once']);
      expect(vm.canContinue, isTrue);
    });
  });

  group('co-pilot flow', () {
    test('has five steps and keeps the language chosen first', () async {
      await start(const OnboardingProgress());
      vm.selectLanguage('zh');
      await vm.next();
      vm.selectRole(OnboardingRole.copilot);
      expect(vm.stepCount, 5);
      expect(vm.progress.language, 'zh');
    });

    test(
      'a link code is checked, then the names, then the co-pilot is linked',
      () async {
        await start(_copilotAt.copyWith(step: OnboardingStep.joinCode));
        expect(vm.canContinue, isFalse);
        vm.setCode('48291');
        expect(vm.canContinue, isFalse);
        vm.setCode(fakeLinkCode);
        await vm.next();
        expect(vm.joinStage, JoinStage.names);
        expect(
          vm.callName,
          fakeProtectedUserName,
          reason: 'prefilled with her name',
        );
        expect(vm.canContinue, isFalse);

        vm.setYourName('Daniel');
        vm.setCallName('Mak');
        await vm.next();
        expect(vm.step, OnboardingStep.notifications);
        final link = rig.onboarding.progress.value.link!;
        expect((link.name, link.phoneNumber), ('Mak', fakeProtectedUserPhone));
        expect(vm.canGoBack, isFalse, reason: 'the link code is used up');
      },
    );

    test(
      'back from the names returns to the code, then leaves the step',
      () async {
        await start(_copilotAt.copyWith(step: OnboardingStep.joinCode));
        vm.setCode(fakeLinkCode);
        await vm.next();
        expect(vm.joinStage, JoinStage.names);
        expect(vm.back(), isTrue);
        expect(vm.joinStage, JoinStage.code);
        expect(vm.step, OnboardingStep.joinCode);
        expect(vm.code, fakeLinkCode, reason: 'what was typed is kept');
        vm.back();
        expect(vm.step, OnboardingStep.role);
      },
    );

    test('each refusal stays on the code with its own error', () async {
      await start(_copilotAt.copyWith(step: OnboardingStep.joinCode));
      for (final (code, error) in [
        ('000000', JoinError.full),
        ('111111', JoinError.expired),
        ('999999', JoinError.invalid),
      ]) {
        vm.setCode(code);
        await vm.next();
        expect(vm.joinError, error);
        expect(vm.joinStage, JoinStage.code);
      }
      vm.setCode('12');
      expect(vm.joinError, isNull, reason: 'typing clears the error');
    });

    test('an unreachable server is a network error, not a refusal', () async {
      await start(_copilotAt.copyWith(step: OnboardingStep.joinCode));
      rig.api.offline = true;
      vm.setCode(fakeLinkCode);
      await vm.next();
      expect(vm.networkError, isTrue);
      expect(vm.joinError, isNull);
    });

    test('notifications: Continue needs the permission', () async {
      await start(_copilotAt.copyWith(step: OnboardingStep.notifications));
      await pump();
      expect(vm.canContinue, isFalse);
      await vm.fix(SetupItem.notifications);
      expect(vm.canContinue, isTrue);
    });
  });
}
