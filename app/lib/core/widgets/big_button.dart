import 'package:flutter/material.dart';

import '../theme/theme_context.dart';

enum BigButtonTone {
  /// Teal fill: the one primary action.
  guarded,

  /// Blue fill: "this may be genuine" actions.
  genuine,

  /// White fill, red text: on the Warning's red field.
  onWarning,

  /// Red fill, white label: the phone's own hang-up colour, on the paper Warning.
  hangUp,

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
    this.maxTextScale,
    this.semanticsLabel,
    this.busy = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final BigButtonTone tone;

  /// Caps the label and icon scale (the Warning passes 1.5); null follows the system.
  final double? maxTextScale;

  /// Shows a spinner in place of the icon. The caller also passes a null [onPressed].
  final bool busy;

  /// Spoken instead of [label] when the label is shortened for the eye.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final cap = maxTextScale;
    if (cap == null) return _build(context);
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: cap,
      child: Builder(builder: _build),
    );
  }

  Widget _build(BuildContext context) {
    final c = context.jagaColors;
    final text = Text(
      label,
      textAlign: TextAlign.center,
      semanticsLabel: semanticsLabel,
    );
    // The icon grows with the text, capped at 2x (a 24dp icon in a 64dp button).
    final scale = MediaQuery.textScalerOf(context).scale(24).clamp(24.0, 48.0);
    final iconWidget = busy
        ? SizedBox.square(
            dimension: scale,
            child: const CircularProgressIndicator(strokeWidth: 3),
          )
        : icon == null
        ? null
        : Icon(icon, size: scale);

    if (tone == BigButtonTone.quiet) {
      return iconWidget == null
          ? OutlinedButton(onPressed: onPressed, child: text)
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: iconWidget,
              label: text,
            );
    }

    final (bg, fg) = switch (tone) {
      BigButtonTone.genuine => (c.genuine, c.onGenuine),
      BigButtonTone.onWarning => (c.onWarning, c.warning),
      BigButtonTone.hangUp => (c.warning, c.onWarning),
      _ => (c.guarded, c.onGuarded),
    };
    final style = FilledButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
    );
    return iconWidget == null
        ? FilledButton(onPressed: onPressed, style: style, child: text)
        : FilledButton.icon(
            onPressed: onPressed,
            style: style,
            icon: iconWidget,
            label: text,
          );
  }
}
