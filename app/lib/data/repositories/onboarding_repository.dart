import 'package:flutter/foundation.dart';

import '../models/linked_person.dart';
import '../models/onboarding_progress.dart';
import '../models/registration.dart';
import '../services/key_value_store.dart';
import '../services/onboarding_api_service.dart';
import 'pin_repository.dart';

const _region = 'MY';
const _progressKey = 'onboarding.progress';

/// The single source of truth for setup. [progress] changes the moment
/// [update] is called and is saved straight after, so the app (locale, which
/// screen is home) and the setup screens always agree.
class OnboardingRepository {
  OnboardingRepository._(this._store, this._api, this._pin, OnboardingProgress start)
    : progress = ValueNotifier(start);

  static Future<OnboardingRepository> load({
    required KeyValueStore store,
    required OnboardingApiService api,
    required PinRepository pin,
  }) async {
    final raw = await store.read(_progressKey);
    return OnboardingRepository._(
      store,
      api,
      pin,
      raw == null ? const OnboardingProgress() : OnboardingProgress.parse(raw),
    );
  }

  final KeyValueStore _store;
  final OnboardingApiService _api;
  final PinRepository _pin;
  final ValueNotifier<OnboardingProgress> progress;

  Future<void> update(OnboardingProgress next) {
    progress.value = next;
    return _store.write(_progressKey, next.toJson());
  }

  /// Registers a protected user. Role and region are locked from then on.
  Future<Registration> register({
    required String personName,
    required String commandLanguage,
  }) => _api.register(
    region: _region,
    commandLanguage: commandLanguage,
    personName: personName,
  );

  Future<List<String>> copilots() =>
      _api.copilots(progress.value.registration!.protectedUserId);

  Future<String> checkLinkCode(String code) => _api.checkLinkCode(code);

  Future<LinkedPerson> join(String code, {required String copilotName}) =>
      _api.join(linkCode: code, copilotName: copilotName);

  /// Back to step 1: forgets the registration, the link and the co-pilot lock.
  Future<void> reset() async {
    await _pin.reset();
    await update(OnboardingProgress(language: progress.value.language));
  }

  void dispose() => progress.dispose();
}
