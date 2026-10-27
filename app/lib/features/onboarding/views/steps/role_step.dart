import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../data/models/onboarding_progress.dart';
import '../../view_models/onboarding_view_model.dart';
import '../widgets/choice_card.dart';

/// Step 2, both roles. Read-only once the server knows who the phone is for.
class RoleStep extends StatelessWidget {
  const RoleStep({super.key, required this.vm});

  final OnboardingViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = context.metrics;
    ChoiceCard card(OnboardingRole role, String title, String body) =>
        ChoiceCard(
          title: title,
          body: body,
          selected: vm.progress.role == role,
          onTap: vm.roleLocked ? null : () => vm.selectRole(role),
        );
    return Column(
      children: [
        card(
          OnboardingRole.protectedUser,
          l.onboardingRoleProtected,
          l.onboardingRoleProtectedBody,
        ),
        SizedBox(height: m.m),
        card(
          OnboardingRole.copilot,
          l.onboardingRoleCopilot,
          l.onboardingRoleCopilotBody,
        ),
      ],
    );
  }
}
