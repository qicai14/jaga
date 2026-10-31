import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';

/// A full-width on/off button of the in-call screen (Mute, Speaker): 64dp or more,
/// the state written out in words, never by colour alone.
class CallToggle extends StatelessWidget {
  const CallToggle({
    super.key,
    required this.icon,
    required this.label,
    required this.trailing,
    required this.on,
    required this.onPressed,
    this.alarm = false,
  });

  final IconData icon;
  final String label;

  /// The state in words ("On", "Off"); empty when [label] already says it.
  final String trailing;
  final bool on;

  /// Null disables it (before the call connects).
  final VoidCallback? onPressed;

  /// On is red with white text (Mute): impossible to miss.
  final bool alarm;

  @override
  Widget build(BuildContext context) {
    final c = context.jagaColors;
    final m = context.metrics;
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg, border) = !on
        ? (null, null, null)
        : alarm
        ? (c.warning, c.onWarning, c.warning)
        : (scheme.primaryContainer, scheme.onPrimaryContainer, scheme.primary);
    final text = Theme.of(context).textTheme.titleMedium?.copyWith(color: fg);
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.5,
      child: Semantics(
        toggled: on,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: Size.fromHeight(m.primaryButtonHeight),
            padding: EdgeInsets.symmetric(horizontal: m.m, vertical: m.s),
            backgroundColor: bg,
            foregroundColor: fg,
            side: border == null ? null : BorderSide(color: border, width: 3),
          ),
          child: Row(
            children: [
              Icon(icon, size: 28),
              SizedBox(width: m.m),
              Expanded(child: Text(label, style: text)),
              if (trailing.isNotEmpty) Text(trailing, style: text),
            ],
          ),
        ),
      ),
    );
  }
}
