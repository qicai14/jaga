import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/big_button.dart';

/// The link code, the only centred element in the app, with Share and the list
/// of co-pilots who joined. Used by the setup step and by settings.
class LinkCodeBody extends StatelessWidget {
  const LinkCodeBody({
    super.key,
    required this.code,
    required this.personName,
    required this.joined,
    required this.onShare,
  });

  final String code;
  final String personName;
  final List<String> joined;
  final ValueChanged<String> onShare;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = context.metrics;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.onboardingLinkBody, style: text.bodyLarge),
        SizedBox(height: m.xl),
        // Two groups of three; TalkBack reads the digits one by one.
        Center(
          child: Semantics(
            label: code.split('').join(' '),
            excludeSemantics: true,
            // Stays on one line however large the text is set.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${code.substring(0, 3)} ${code.substring(3)}',
                style: context.jagaText.linkCode,
              ),
            ),
          ),
        ),
        SizedBox(height: m.xl),
        BigButton(
          tone: BigButtonTone.quiet,
          icon: Icons.share,
          label: l.commonShare,
          onPressed: () => onShare(l.onboardingLinkShareText(code, personName)),
        ),
        SizedBox(height: m.l),
        Text(l.onboardingJoined, style: text.bodyMedium),
        Semantics(
          liveRegion: true,
          child: Text(
            joined.isEmpty ? l.onboardingJoinedNone : joined.join(', '),
            style: text.titleLarge,
          ),
        ),
      ],
    );
  }
}
