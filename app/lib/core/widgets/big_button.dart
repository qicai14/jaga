import 'package:flutter/material.dart';

import '../theme/theme_context.dart';

enum BigButtonTone {
  /// Teal fill: the one primary action.
  guarded,

  /// Blue fill: "this may be genuine" actions.
  genuine,

  /// White fill, red text: on the Warning's red field.
  onWarning,

  /// Outlined, no fill.
  quiet,
}

/// The one primary action: full width, 64dp tall, label wraps (no ellipsis).
class BigButton extends StatelessWidget {
  const BigButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.tone = BigButtonTone.guarded,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final BigButtonTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.jagaColors;
    final text = Text(label, textAlign: TextAlign.center);
    final iconWidget = icon == null ? null : Icon(icon);

    if (tone == BigButtonTone.quiet) {
      return iconWidget == null
          ? OutlinedButton(onPressed: onPressed, child: text)
          : OutlinedButton.icon(
              onPressed: onPressed, icon: iconWidget, label: text);
    }

    final (bg, fg) = switch (tone) {
      BigButtonTone.genuine => (c.genuine, c.onGenuine),
      BigButtonTone.onWarning => (c.onWarning, c.warning),
      _ => (c.guarded, c.onGuarded),
    };
    final style = FilledButton.styleFrom(backgroundColor: bg, foregroundColor: fg);
    return iconWidget == null
        ? FilledButton(onPressed: onPressed, style: style, child: text)
        : FilledButton.icon(
            onPressed: onPressed, style: style, icon: iconWidget, label: text);
  }
}
