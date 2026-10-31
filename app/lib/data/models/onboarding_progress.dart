import 'dart:convert';

import 'linked_person.dart';
import 'registration.dart';

enum OnboardingRole { protectedUser, copilot }

enum OnboardingStep {
  language,
  role,
  about,
  permissions,
  forwarding,
  pin,
  pauseToken,
  linkCode,
  buzz,
  done,
  joinCode,
  notifications;

  static const _protectedUserSteps = [
    language,
    role,
    about,
    permissions,
    forwarding,
    pin,
    pauseToken,
    linkCode,
    buzz,
    done,
  ];
  static const _copilotSteps = [language, role, joinCode, notifications, done];

  /// The steps of [role], in order; before a role is chosen, the longer list
  /// (the screen shows no count until then).
  static List<OnboardingStep> of(OnboardingRole? role) =>
      role == OnboardingRole.copilot ? _copilotSteps : _protectedUserSteps;
}

/// Where setup stands. Saved after every change; a relaunch resumes here.
/// Kept after setup finishes ([complete]): the status screen and settings read it.
class OnboardingProgress {
  const OnboardingProgress({
    this.role,
    this.step = OnboardingStep.language,
    this.language = 'ms',
    this.personName = '',
    this.pinSet = false,
    this.registration,
    this.link,
    this.complete = false,
  });

  factory OnboardingProgress.parse(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final reg = json['registration'] as Map<String, dynamic>?;
    final link = json['link'] as Map<String, dynamic>?;
    return OnboardingProgress(
      role: json['role'] == null
          ? null
          : OnboardingRole.values.byName(json['role'] as String),
      step: OnboardingStep.values.byName(json['step'] as String),
      language: json['language'] as String,
      personName: json['personName'] as String,
      pinSet: json['pinSet'] as bool,
      registration: reg == null ? null : Registration.fromJson(reg),
      link: link == null
          ? null
          : LinkedPerson(
              name: link['name'] as String,
              phoneNumber: link['phoneNumber'] as String?,
            ),
      complete: json['complete'] as bool,
    );
  }

  final OnboardingRole? role;
  final OnboardingStep step;

  /// App language, chosen first; on a protected user's phone also the command language.
  final String language;

  /// What the family calls the protected user.
  final String personName;
  final bool pinSet;

  /// Protected user only, set at the end of the "About her" step.
  final Registration? registration;

  /// Co-pilot only, set when the link code is accepted.
  final LinkedPerson? link;
  final bool complete;

  List<OnboardingStep> get steps => OnboardingStep.of(role);

  OnboardingProgress copyWith({
    OnboardingRole? role,
    OnboardingStep? step,
    String? language,
    String? personName,
    bool? pinSet,
    Registration? registration,
    LinkedPerson? link,
    bool? complete,
  }) => OnboardingProgress(
    role: role ?? this.role,
    step: step ?? this.step,
    language: language ?? this.language,
    personName: personName ?? this.personName,
    pinSet: pinSet ?? this.pinSet,
    registration: registration ?? this.registration,
    link: link ?? this.link,
    complete: complete ?? this.complete,
  );

  String toJson() => jsonEncode({
    'role': role?.name,
    'step': step.name,
    'language': language,
    'personName': personName,
    'pinSet': pinSet,
    'registration': registration?.toJson(),
    'link': link == null
        ? null
        : {'name': link!.name, 'phoneNumber': link!.phoneNumber},
    'complete': complete,
  });
}
