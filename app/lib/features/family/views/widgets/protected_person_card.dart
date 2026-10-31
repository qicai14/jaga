import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/big_button.dart';
import '../../../../core/widgets/status_badge.dart';

/// Whom the co-pilot protects, that Jaga is guarding them, and, while Jaga
/// Pause is on, the way to clear it.
class ProtectedPersonCard extends StatelessWidget {
  const ProtectedPersonCard({
    super.key,
    required this.name,
    required this.pauseActive,
    required this.onClearPause,
  });

  final String name;
  final bool pauseActive;
  final VoidCallback onClearPause;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = context.metrics;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(m.l),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(m.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: Theme.of(context).textTheme.headlineMedium),
          SizedBox(height: m.s),
          Wrap(
            spacing: m.s,
            runSpacing: m.s,
            children: [
              StatusBadge(label: l.familyHomeProtected, icon: Icons.shield),
              if (pauseActive)
                StatusBadge(
                  label: l.statusPauseActive,
                  tone: BadgeTone.caution,
                  icon: Icons.pause_circle,
                ),
            ],
          ),
          if (pauseActive) ...[
            SizedBox(height: m.m),
            BigButton(
              tone: BigButtonTone.quiet,
              label: l.familyClearPause,
              onPressed: onClearPause,
            ),
          ],
        ],
      ),
    );
  }
}
