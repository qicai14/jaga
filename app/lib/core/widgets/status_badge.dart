import 'package:flutter/material.dart';

import '../theme/theme_context.dart';

enum BadgeTone { guarded, caution, genuine, neutral }

/// A pill that states a status. Not tappable. Never red (red means Warning).
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, this.tone = BadgeTone.guarded, this.icon});

  final String label;
  final BadgeTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.jagaColors;
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (tone) {
      BadgeTone.guarded => (c.guardedContainer, c.onGuardedContainer),
      BadgeTone.caution => (c.caution, c.onCaution),
      BadgeTone.genuine => (c.genuineContainer, c.onGenuineContainer),
      BadgeTone.neutral => (scheme.surfaceContainerHigh, scheme.onSurface),
    };
    final m = context.metrics;
    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: EdgeInsets.symmetric(horizontal: m.m, vertical: m.xs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(m.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 24, color: fg),
            SizedBox(width: m.s),
          ],
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}
