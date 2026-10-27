import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/hold_to_confirm_button.dart';
import '../../../../core/widgets/jaga_wordmark.dart';
import '../../../../core/widgets/reconnecting_dot.dart';
import 'dismiss_button.dart';

/// Medium risk: an amber banner over the top of the call screen. No command,
/// no buzz. The call controls below stay usable.
class CautionBanner extends StatelessWidget {
  const CautionBanner({
    super.key,
    required this.reconnecting,
    required this.onDismiss,
  });

  final bool reconnecting;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.jagaColors;
    final m = context.metrics;
    final instant = MediaQuery.disableAnimationsOf(context);

    // Clamped so the banner stays within about 40% of the screen at large text sizes.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.5,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: instant ? Duration.zero : const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        builder: (context, t, child) => ClipRect(
          child: Align(
            alignment: Alignment.bottomCenter,
            heightFactor: t,
            child: child,
          ),
        ),
        child: Semantics(
          liveRegion: true,
          container: true,
          child: Material(
            type: MaterialType.transparency,
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(m.radiusMedium),
              ),
              child: ColoredBox(
                color: c.caution,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(m.l, m.m, m.l, m.m),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                JagaWordmark(
                                  color: c.onCaution,
                                  size: JagaWordmarkSize.small,
                                ),
                                const Spacer(),
                                if (reconnecting)
                                  ReconnectingDot(
                                    visible: true,
                                    color: c.onCaution,
                                  ),
                              ],
                            ),
                            SizedBox(height: m.s),
                            Text(
                              l.cautionBannerText,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(color: c.onCaution),
                            ),
                            SizedBox(height: m.m),
                            DismissButton(
                              tone: HoldTone.calm,
                              onConfirmed: onDismiss,
                            ),
                          ],
                        ),
                      ),
                    ),
                    ColoredBox(
                      color: c.cautionEdge,
                      child: const SizedBox(height: 3, width: double.infinity),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
