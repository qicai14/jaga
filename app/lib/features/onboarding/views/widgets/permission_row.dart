import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';

/// One line of the permissions checklist: a tick or a cross, what it is for,
/// and a Fix button while it is not granted. [pending] is for a permission that
/// waits for a later feature: neither ticked nor a problem.
class PermissionRow extends StatelessWidget {
  const PermissionRow({
    super.key,
    required this.title,
    required this.why,
    required this.granted,
    this.onFix,
    this.onConfirm,
    this.pending = false,
  });

  final String title;
  final String why;
  final bool granted;
  final bool pending;
  final VoidCallback? onFix;

  /// For a permission Android can't report: the family ticks it by hand.
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = context.metrics;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final (icon, color) = granted
        ? (Icons.check_circle, context.jagaColors.guarded)
        : pending
        ? (Icons.schedule, context.jagaColors.muted)
        : (Icons.error_outline, scheme.error);
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: EdgeInsets.only(bottom: m.l),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: color),
            SizedBox(width: m.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.titleLarge),
                  Text(why, style: text.bodyMedium),
                  if (!granted && (onFix != null || onConfirm != null))
                    Padding(
                      padding: EdgeInsets.only(top: m.s),
                      child: Wrap(
                        spacing: m.s,
                        runSpacing: m.s,
                        children: [
                          if (onFix != null)
                            OutlinedButton(
                              onPressed: onFix,
                              child: Text(l.onboardingFix),
                            ),
                          if (onConfirm != null)
                            OutlinedButton(
                              onPressed: onConfirm,
                              child: Text(l.onboardingFixedIt),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
