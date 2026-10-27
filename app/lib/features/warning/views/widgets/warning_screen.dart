import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/big_button.dart';
import '../../../../core/widgets/hold_to_confirm_button.dart';
import '../../../../core/widgets/jaga_wordmark.dart';
import '../../../../core/widgets/reconnecting_dot.dart';
import '../../../../core/widgets/shrink_to_fit_text.dart';
import '../../view_models/warning_view_model.dart';
import 'dismiss_button.dart';

/// The full-screen Warning (high risk), "the Jaga notice": a teal Jaga masthead,
/// the command on one red band, then the counter-move with the official number
/// and the evidence on paper. Only Hang up is pinned; dismiss ends the scroll.
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
  final _scroll = ScrollController();

  /// The command did not fit at the 32sp floor: it takes the space it needs and
  /// the band itself scrolls (last resort, huge text).
  bool _commandOverflows = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

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
    final instant = MediaQuery.disableAnimationsOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: PopScope(
        canPop: false,
        child: Semantics(
          scopesRoute: true,
          namesRoute: true,
          explicitChildNodes: true,
          label: l.warningFromJaga,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: instant
                ? Duration.zero
                : const Duration(milliseconds: 150),
            builder: (context, t, child) =>
                Opacity(opacity: t, alwaysIncludeSemantics: true, child: child),
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              child: LayoutBuilder(
                builder: (context, box) {
                  final pad = MediaQuery.paddingOf(context);
                  final body = box.maxHeight - pad.top - pad.bottom;
                  return Column(
                    children: [
                      _masthead(context),
                      _commandBand(context, body * 0.30),
                      Expanded(child: _detail(context)),
                      _footer(context),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _masthead(BuildContext context) {
    final c = context.jagaColors;
    final m = context.metrics;
    final l = AppLocalizations.of(context);
    return Semantics(
      header: true,
      child: ColoredBox(
        color: c.guarded,
        child: SafeArea(
          bottom: false,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: EdgeInsets.only(left: m.l, right: m.s),
              child: Row(
                children: [
                  // The route name already says "Scam warning from Jaga".
                  Expanded(
                    child: ExcludeSemantics(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          JagaWordmark(color: c.onGuarded),
                          SizedBox(width: m.m),
                          Expanded(
                            child: MediaQuery.withClampedTextScaling(
                              maxScaleFactor: 1.5,
                              child: Text(
                                l.warningSemanticsLabel,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(color: c.onGuarded),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ReconnectingDot(
                    visible: widget.reconnecting,
                    color: c.onGuarded,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _commandBand(BuildContext context, double maxHeight) {
    final l = AppLocalizations.of(context);
    final c = context.jagaColors;
    final m = context.metrics;
    final styles = context.jagaText;
    final content = widget.content;
    final command = content.command ?? l.warningCommandFallback;
    // Shown once: when her language is missing the server sends English.
    final english = content.command == null ? null : content.commandEnglish;
    final scale = MediaQuery.textScalerOf(context).scale(1);

    final band = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _commandOverflows
            ? Text(
                command,
                style: styles.command.copyWith(
                  fontSize: 32 / max(1.0, scale),
                  color: c.onWarning,
                ),
              )
            : Flexible(
                child: ShrinkToFitText(
                  text: command,
                  style: styles.command.copyWith(color: c.onWarning),
                  // The 32sp floor is what she sees, so it is divided by the scale.
                  minFontSize: 32 / max(1.0, scale),
                  onOverflow: () {
                    if (mounted) setState(() => _commandOverflows = true);
                  },
                ),
              ),
        if (english != null && english != command) ...[
          SizedBox(height: m.s),
          // Secondary line: unscaled (30sp) so it never outsizes a shrunk command.
          MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.0,
            child: Text(
              english,
              style: styles.commandEnglish.copyWith(color: c.onWarning),
            ),
          ),
        ],
      ],
    );

    return SizedBox(
      width: double.infinity,
      child: ColoredBox(
        color: c.warning,
        child: _commandOverflows
            ? ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight * 1.5),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(m.l),
                  child: band,
                ),
              )
            : ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: Padding(padding: EdgeInsets.all(m.l), child: band),
              ),
      ),
    );
  }

  Widget _detail(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final m = context.metrics;
    final text = Theme.of(context).textTheme;
    final styles = context.jagaText;
    final content = widget.content;
    final counterEnglish = content.counterMoveEnglish;
    final number = content.officialNumber;
    // Never on the credentials Warning (Q36).
    final evidence = content.isCredentials || content.evidence.isEmpty
        ? null
        : content.evidence.first;

    // Body text is capped at 1.4 on this screen (31sp is still the largest in the app).
    final texts = MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.4,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (content.counterMove != null)
              Text(
                content.counterMove!,
                style: text.bodyLarge?.copyWith(color: scheme.onSurface),
              ),
            if (number != null) ...[
              SizedBox(height: m.l),
              Text(
                content.agency == null
                    ? l.warningOfficialNumberLabelNoAgency
                    : l.warningOfficialNumberLabel(content.agency!),
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              // One line, never wraps; it shrinks instead. Read one numeral at a time.
              MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.2,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    number,
                    maxLines: 1,
                    softWrap: false,
                    semanticsLabel: number.replaceAllMapped(
                      RegExp(r'\d'),
                      (d) => '${d[0]} ',
                    ),
                    style: styles.officialNumber.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ),
            ],
            if (counterEnglish != null &&
                counterEnglish != content.counterMove) ...[
              SizedBox(height: m.m),
              Text(
                counterEnglish,
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (evidence != null) ...[
              Divider(height: m.xl, color: scheme.outlineVariant),
              Text(
                l.warningEvidenceLabel,
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Text(
                '“$evidence”',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: text.bodyLarge?.copyWith(color: scheme.onSurface),
              ),
            ],
          ],
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, box) => Scrollbar(
        controller: _scroll,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scroll,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight),
            child: Padding(
              padding: EdgeInsets.all(m.l),
              // At 1.0 the dismiss rests just above Hang up; at large text it
              // follows the content.
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  texts,
                  SizedBox(height: m.xl),
                  DismissButton(
                    tone: HoldTone.calm,
                    maxTextScale: 1.5,
                    onConfirmed: widget.onDismiss,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _footer(BuildContext context) {
    final m = context.metrics;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: m.l, vertical: m.m),
        child: BigButton(
          tone: BigButtonTone.hangUp,
          icon: Icons.call_end,
          label: AppLocalizations.of(context).warningHangUp,
          maxTextScale: 1.5,
          onPressed: widget.onHangUp,
        ),
      ),
    );
  }
}
