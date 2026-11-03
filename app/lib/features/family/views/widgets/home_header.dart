import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/jaga_seal.dart';
import '../../../../core/widgets/jaga_wordmark.dart';

/// The top of the co-pilot Home: the Jaga seal and wordmark like a letterhead,
/// and a fixed line saying whom they watch over. It never reflects call or
/// pause state: the card and the live tile say that.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = context.metrics;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const JagaSeal(),
        SizedBox(width: m.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The wordmark hides itself from TalkBack: this is the header.
              Semantics(
                header: true,
                label: l.appTitle,
                child: JagaWordmark(
                  size: JagaWordmarkSize.display,
                  color: context.jagaColors.guarded,
                ),
              ),
              SizedBox(height: m.xs),
              Text(
                l.familyHomeWatching(name),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
