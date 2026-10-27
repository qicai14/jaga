import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/data/models/onboarding_progress.dart';
import 'package:jaga/data/repositories/onboarding_repository.dart';
import 'package:jaga/data/repositories/pin_repository.dart';
import 'package:jaga/data/services/key_value_store.dart';
import 'package:jaga/data/services/onboarding_api_service.dart';

void main() {
  late InMemoryStore store;
  late DateTime now;
  late PinRepository pin;

  PinRepository open() => PinRepository(store: store, clock: () => now);

  setUp(() {
    store = InMemoryStore();
    now = DateTime(2026, 10, 27, 12);
    pin = open();
  });

  Future<void> wrongTries(int n) async {
    for (var i = 0; i < n; i++) {
      await pin.verify('0000');
    }
  }

  test('stores a salted hash, never the digits', () async {
    await pin.set('1234');
    expect(store.values.values.any((v) => v.contains('1234')), isFalse);
    final first = store.values['pin.hash'];
    await pin.set('1234');
    expect(store.values['pin.hash'], isNot(first), reason: 'new salt each time');
    expect(await pin.verify('1234'), PinResult.ok);
  });

  test('a wrong PIN is wrong, and the right one still works after', () async {
    await pin.set('1234');
    expect(await pin.verify('4321'), PinResult.wrong);
    expect(await pin.verify('1234'), PinResult.ok);
  });

  test('five wrong tries lock for five minutes, even for the right PIN', () async {
    await pin.set('1234');
    await wrongTries(4);
    expect(await pin.verify('0000'), PinResult.locked);
    expect(await pin.lockedUntil(), now.add(const Duration(minutes: 5)));

    now = now.add(const Duration(minutes: 4, seconds: 59));
    expect(await pin.verify('1234'), PinResult.locked);

    now = now.add(const Duration(seconds: 1));
    expect(await pin.lockedUntil(), isNull);
    expect(await pin.verify('1234'), PinResult.ok);
  });

  test('the lock and the tries survive a restart', () async {
    await pin.set('1234');
    await wrongTries(5);
    expect(await open().verify('1234'), PinResult.locked);
  });

  test('a right PIN clears the wrong tries', () async {
    await pin.set('1234');
    await wrongTries(4);
    expect(await pin.verify('1234'), PinResult.ok);
    await wrongTries(4);
    expect(await pin.verify('1234'), PinResult.ok);
  });

  test('progress is saved after every update and resumes on the next launch', () async {
    final api = FakeOnboardingApiService();
    final repo = await OnboardingRepository.load(store: store, api: api, pin: pin);
    expect(repo.progress.value.step, OnboardingStep.role);
    await repo.update(
      repo.progress.value.copyWith(
        role: OnboardingRole.protectedUser,
        step: OnboardingStep.pin,
        language: 'ta',
        registration: fakeRegistration,
      ),
    );
    final again = await OnboardingRepository.load(store: store, api: api, pin: pin);
    final p = again.progress.value;
    expect((p.role, p.step, p.language), (OnboardingRole.protectedUser, OnboardingStep.pin, 'ta'));
    expect(p.registration!.linkCode, fakeLinkCode);
  });

  test('reset forgets the registration and the PIN but keeps the language', () async {
    final repo = await OnboardingRepository.load(
      store: store,
      api: FakeOnboardingApiService(),
      pin: pin,
    );
    await pin.set('1234');
    await repo.update(
      const OnboardingProgress(
        role: OnboardingRole.protectedUser,
        language: 'en',
        registration: fakeRegistration,
        complete: true,
      ),
    );
    await repo.reset();
    expect(repo.progress.value.role, isNull);
    expect(repo.progress.value.language, 'en');
    expect(repo.progress.value.complete, isFalse);
    expect(await pin.verify('1234'), PinResult.wrong);
  });
}
