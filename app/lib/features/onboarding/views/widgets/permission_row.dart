import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/shrink_to_fit_text.dart';

/// One line of the permissions checklist: a tick or a cross, what it is for,
/// and a Fix button while it is not granted.
class PermissionRow extends StatelessWidget {
  const PermissionRow({
    super.key,
    required this.title,
    required this.why,
    required this.granted,
    this.onFix,
    this.onConfirm,
    this.fixWhenGranted = false,
  });

  final String title;
  final String why;
  final bool granted;
  final VoidCallback? onFix;

  /// For a permission Android can't report: the family ticks it by hand.
  final VoidCallback? onConfirm;

  /// Keep Fix after the tick: a phone update can reset what Android can't report.
  final bool fixWhenGranted;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = context.metrics;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final (icon, color) = granted
        ? (Icons.check_circle, context.jagaColors.guarded)
        : (Icons.error_outline, scheme.error);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Steps down only when a word would split (never below body size).
        ShrinkToFitText(
          text: title,
          style: text.titleLarge!,
          minFontSize: 20,
          wholeWords: true,
        ),
        Text(why, style: text.bodyMedium),
        if (onFix != null && (!granted || fixWhenGranted) ||
            !granted && onConfirm != null)
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
                if (!granted && onConfirm != null)
                  OutlinedButton(
                    onPressed: onConfirm,
                    child: Text(l.onboardingFixedIt),
                  ),
              ],
            ),
          ),
      ],
    );
    final mark = Icon(icon, size: 32, color: color);
    // At large text the icon goes above the text, so a long word like
    // "Pemberitahuan" gets the full width instead of splitting.
    // Probed at the real title size: Android 14+ scales large text nonlinearly.
    final size = text.titleLarge!.fontSize!;
    final large = MediaQuery.textScalerOf(context).scale(size) / size > 1.5;
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: EdgeInsets.only(bottom: m.l),
        child: large
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  mark,
                  SizedBox(height: m.s),
                  content,
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  mark,
                  SizedBox(width: m.m),
                  Expanded(child: content),
                ],
              ),
      ),
    );
  }
}
