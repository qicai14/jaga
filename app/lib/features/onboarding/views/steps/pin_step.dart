import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/pin_pad.dart';
import '../../view_models/onboarding_view_model.dart';
import '../widgets/inline_error.dart';

/// Step 6: set the co-pilot lock, then enter it again.
class PinStep extends StatelessWidget {
  const PinStep({super.key, required this.vm});

  final OnboardingViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = context.metrics;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.onboardingPinBody, style: text.bodyLarge),
        if (vm.confirmingPin) ...[
          SizedBox(height: m.m),
          Semantics(
            liveRegion: true,
            child: Text(l.onboardingPinConfirm, style: text.titleLarge),
          ),
        ],
        if (vm.pinMismatch) InlineError(l.onboardingPinMismatch),
        SizedBox(height: m.l),
        PinPad(onCompleted: vm.submitPin),
      ],
    );
  }
}
