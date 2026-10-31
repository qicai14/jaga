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
        // The prompt and the error share one slot, sized for the taller, so the
        // keypad never moves while the PIN is typed.
        Stack(
          children: [
            _Slot(
              visible: vm.confirmingPin,
              child: Padding(
                padding: EdgeInsets.only(top: m.m),
                child: Semantics(
                  liveRegion: true,
                  child: Text(l.onboardingPinConfirm, style: text.titleLarge),
                ),
              ),
            ),
            _Slot(
              visible: vm.pinMismatch,
              child: InlineError(l.onboardingPinMismatch),
            ),
          ],
        ),
        SizedBox(height: m.l),
        // A new key empties the pad when the entry changes.
        PinPad(
          key: ValueKey(vm.confirmingPin),
          length: OnboardingViewModel.pinLength,
          onChanged: vm.setPinDigits,
        ),
      ],
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) => Visibility(
    visible: visible,
    maintainSize: true,
    maintainAnimation: true,
    maintainState: true,
    child: child,
  );
}
