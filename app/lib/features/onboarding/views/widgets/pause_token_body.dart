import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';

/// The Jaga Pause token, in groups of four, with Copy and Share. Used by the
/// setup step and by settings.
class PauseTokenBody extends StatelessWidget {
  const PauseTokenBody({super.key, required this.token, required this.onShare});

  final String token;
  final ValueChanged<String> onShare;

  /// "JAGA-7Q4M-2KXP-9D3F" reads as "JAGA 7Q4M 2KXP 9D3F".
  static String grouped(String token) {
    final raw = token.replaceAll('-', '');
    return [
      for (var i = 0; i < raw.length; i += 4)
        raw.substring(i, i + 4 > raw.length ? raw.length : i + 4),
    ].join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = context.metrics;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.onboardingPauseBody, style: text.bodyLarge),
        SizedBox(height: m.l),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(m.m),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(m.radiusSmall),
          ),
          child: SelectableText(grouped(token), style: text.bodyLarge),
        ),
        SizedBox(height: m.m),
        Wrap(
          spacing: m.s,
          runSpacing: m.s,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.copy),
              label: Text(l.commonCopy),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: token));
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(l.commonCopied)));
              },
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.share),
              label: Text(l.commonShare),
              onPressed: () => onShare(token),
            ),
          ],
        ),
      ],
    );
  }
}
