import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/big_button.dart';
import '../../../../core/widgets/hold_to_confirm_button.dart';
import '../../../../core/widgets/reconnecting_dot.dart';
import '../../../../core/widgets/shrink_to_fit_text.dart';
import '../../view_models/warning_view_model.dart';
import 'dismiss_button.dart';

/// The full-screen Warning (high risk): the command first, then the counter-move
/// with the official number, then the evidence. Edge to edge, red, no radius.
class WarningScreen extends StatefulWidget {
  const WarningScreen({
    super.key,
    required this.content,
    required this.reconnecting,
    required this.onHangUp,
    required this.onDismiss,
  });

  final WarningContent content;
  final bool reconnecting;
  final VoidCallback onHangUp;
  final VoidCallback onDismiss;

  @override
  State<WarningScreen> createState() => _WarningScreenState();
}

class _WarningScreenState extends State<WarningScreen> {
  /// The command did not fit at the 32sp floor: it takes the space it needs and
  /// only the lower region scrolls.
  bool _commandOverflows = false;

  @override
  void didUpdateWidget(WarningScreen old) {
    super.didUpdateWidget(old);
    if (old.content.command != widget.content.command) {
      _commandOverflows = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.jagaColors;
    final m = context.metrics;
    final text = Theme.of(context).textTheme;
    final styles = context.jagaText;
    final content = widget.content;
    final instant = MediaQuery.disableAnimationsOf(context);
    // Big text: the counter-move clamps so the official number is reachable.
    final bigText = MediaQuery.textScalerOf(context).scale(10) >= 15;

    final command = content.command ?? l.warningCommandFallback;
    final english = content.command == null ? null : content.commandEnglish;
    final counterEnglish = content.counterMoveEnglish;
    final number = content.officialNumber;
    // Never on the credentials Warning (Q36).
    final evidence = content.isCredentials || content.evidence.isEmpty
        ? null
        : content.evidence.first;

    final commandRegion = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _commandOverflows
            ? Text(
                command,
                style: styles.command.copyWith(
                  fontSize: 32,
                  color: c.onWarning,
                ),
              )
            : Flexible(
                child: ShrinkToFitText(
                  text: command,
                  style: styles.command.copyWith(color: c.onWarning),
                  onOverflow: () {
                    if (mounted) setState(() => _commandOverflows = true);
                  },
                ),
              ),
        // Shown once: when her language is missing the server sends English.
        if (english != null && english != command) ...[
          SizedBox(height: m.s),
          Text(
            english,
            style: styles.commandEnglish.copyWith(color: c.onWarning),
          ),
        ],
      ],
    );

    final detail = SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (content.counterMove != null)
            Text(
              content.counterMove!,
              maxLines: bigText ? 2 : null,
              overflow: bigText ? TextOverflow.ellipsis : null,
              style: text.bodyLarge?.copyWith(color: c.onWarning),
            ),
          if (counterEnglish != null &&
              counterEnglish != content.counterMove) ...[
            SizedBox(height: m.s),
            Text(
              counterEnglish,
              maxLines: bigText ? 2 : null,
              overflow: bigText ? TextOverflow.ellipsis : null,
              style: text.bodyMedium?.copyWith(color: c.onWarning),
            ),
          ],
          if (number != null) ...[
            SizedBox(height: m.m),
            Text(
              content.agency == null
                  ? l.warningOfficialNumberLabelNoAgency
                  : l.warningOfficialNumberLabel(content.agency!),
              style: text.bodyMedium?.copyWith(color: c.onWarning),
            ),
            // Read digit by digit, not as a quantity.
            Text(
              number,
              semanticsLabel: number.replaceAllMapped(
                RegExp(r'\d'),
                (d) => '${d[0]} ',
              ),
              style: styles.officialNumber.copyWith(color: c.warningNumber),
            ),
          ],
          if (evidence != null) ...[
            SizedBox(height: m.l),
            Text(
              l.warningEvidenceLabel,
              style: text.bodyMedium?.copyWith(color: c.onWarning),
            ),
            Text(
              '“$evidence”',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: text.bodyLarge?.copyWith(
                color: c.onWarning,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );

    final rule = Divider(
      height: m.l,
      thickness: 2,
      color: c.onWarning.withValues(alpha: 0.4),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: PopScope(
        canPop: false,
        child: Semantics(
          scopesRoute: true,
          namesRoute: true,
          explicitChildNodes: true,
          label: l.warningSemanticsLabel,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: instant
                ? Duration.zero
                : const Duration(milliseconds: 300),
            builder: (context, t, child) {
              // First 200 ms the red field wipes down; the last 100 ms the content fades in.
              final wipe = Curves.easeOutCubic.transform((t * 1.5).clamp(0, 1));
              final fade = ((t - 2 / 3) * 3).clamp(0.0, 1.0);
              return ClipRect(
                clipper: _TopReveal(wipe),
                child: ColoredBox(
                  color: c.warning,
                  child: Opacity(
                    opacity: fade,
                    alwaysIncludeSemantics: true,
                    child: child,
                  ),
                ),
              );
            },
            child: Material(
              color: c.warning,
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: m.l),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ExcludeSemantics(
                            child: Icon(
                              content.isCredentials
                                  ? Icons.pan_tool
                                  : Icons.call_end,
                              size: 40,
                              color: c.onWarning,
                            ),
                          ),
                          const Spacer(),
                          ReconnectingDot(
                            visible: widget.reconnecting,
                            color: c.onWarning.withValues(alpha: 0.6),
                          ),
                        ],
                      ),
                      if (_commandOverflows)
                        // Last resort (huge text): the command is still first, at
                        // its 32sp floor, but it scrolls with the rest.
                        Flexible(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [commandRegion, rule, detail],
                            ),
                          ),
                        )
                      else
                        // The command sizes to its content (up to 55% of the
                        // room, then it shrinks); the detail gets the rest.
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, box) => Column(
                              children: [
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight: box.maxHeight * 0.55,
                                  ),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: commandRegion,
                                  ),
                                ),
                                rule,
                                Expanded(
                                  child: SingleChildScrollView(child: detail),
                                ),
                              ],
                            ),
                          ),
                        ),
                      SizedBox(height: m.s),
                      BigButton(
                        tone: BigButtonTone.onWarning,
                        icon: Icons.call_end,
                        label: l.warningHangUp,
                        onPressed: widget.onHangUp,
                      ),
                      SizedBox(height: m.s),
                      DismissButton(
                        tone: HoldTone.onWarning,
                        onConfirmed: widget.onDismiss,
                      ),
                      SizedBox(height: m.m),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Reveals the top [fraction] of the box.
class _TopReveal extends CustomClipper<Rect> {
  const _TopReveal(this.fraction);

  final double fraction;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width, size.height * fraction);

  @override
  bool shouldReclip(_TopReveal old) => old.fraction != fraction;
}
