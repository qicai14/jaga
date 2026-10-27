import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/big_button.dart';

/// The call forwarding code with Dial now and Check forwarding. Used by the
/// setup step and by settings.
class ForwardingBody extends StatelessWidget {
  const ForwardingBody({
    super.key,
    required this.code,
    required this.onDial,
    required this.onCheck,
  });

  final String code;
  final VoidCallback onDial;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = context.metrics;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.onboardingForwardBody,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        SizedBox(height: m.l),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(m.m),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(m.radiusSmall),
          ),
          // The code has no spaces to wrap at, so it shrinks to fit one line.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: SelectableText(code, style: context.jagaText.officialNumber),
          ),
        ),
        SizedBox(height: m.l),
        BigButton(
          label: l.onboardingDialNow,
          icon: Icons.call,
          onPressed: onDial,
        ),
        SizedBox(height: m.m),
        OutlinedButton(
          onPressed: onCheck,
          child: Text(l.onboardingCheckForwarding),
        ),
      ],
    );
  }
}
