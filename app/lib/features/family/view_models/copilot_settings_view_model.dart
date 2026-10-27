import 'package:flutter/foundation.dart';

import '../../../data/models/linked_person.dart';
import '../../../data/repositories/onboarding_repository.dart';

/// The co-pilot's settings: their app language, and unlinking from the
/// protected user.
class CopilotSettingsViewModel extends ChangeNotifier {
  CopilotSettingsViewModel({required this._repository, required this.person});

  final OnboardingRepository _repository;
  final LinkedPerson person;

  String get language => _repository.progress.value.language;

  void selectLanguage(String code) {
    _repository.update(_repository.progress.value.copyWith(language: code));
    notifyListeners();
  }

  /// Forgets the link on this phone and goes back to setup. The server is not
  /// told: there is no unlink endpoint yet (requested from contracts #1).
  Future<void> unlink() => _repository.reset();
}
