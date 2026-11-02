import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/big_button.dart';
import '../../view_models/onboarding_view_model.dart';

/// Step 9: feel the Warning buzz once. Buzz only, no sound.
class BuzzStep extends StatelessWidget {
  const BuzzStep({super.key, required this.vm});

  final OnboardingViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.onboardingBuzzBody,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        SizedBox(height: context.metrics.l),
        BigButton(
          tone: BigButtonTone.quiet,
          icon: Icons.vibration,
          label: l.onboardingBuzzButton,
          onPressed: vm.playBuzz,
        ),
      ],
    );
  }
}
