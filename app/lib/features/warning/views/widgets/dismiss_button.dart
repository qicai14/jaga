import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/widgets/hold_to_confirm_button.dart';

/// "This call is fine" hold-to-confirm, with the English line when her
/// language is not English (shown while she holds).
class DismissButton extends StatelessWidget {
  const DismissButton({
    super.key,
    required this.tone,
    required this.onConfirmed,
    this.maxTextScale,
  });

  final HoldTone tone;
  final VoidCallback onConfirmed;
  final double? maxTextScale;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isEnglish = l.localeName == 'en';
    return HoldToConfirmButton(
      label: l.warningDismissLabel,
      secondLabel: isEnglish
          ? null
          : lookupAppLocalizations(const Locale('en')).warningDismissLabel,
      tone: tone,
      height: 56,
      maxTextScale: maxTextScale,
      hint: l.warningDismissHint,
      confirmHint: l.warningDismissConfirmHint,
      onConfirmed: onConfirmed,
    );
  }
}
