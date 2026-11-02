import 'package:flutter/material.dart';

import '../../../../core/l10n/date_text.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/l10n/stage_labels.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../data/models/alerted_call.dart';
import '../../../../data/models/stage_update.dart';
import 'quote_block.dart';

/// One step of the timeline: time, stage, a badge when the risk changed, and
/// the masked quotes. A rail on the left joins the steps.
class TimelineEventRow extends StatelessWidget {
  const TimelineEventRow({
    super.key,
    required this.event,
    required this.riskChanged,
    required this.last,
  });

  final TimelineEvent event;

  /// The risk differs from the step before: say so.
  final bool riskChanged;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = context.metrics;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExcludeSemantics(
            child: SizedBox(
              width: m.m,
              child: Column(
                children: [
                  Container(
                    width: m.m,
                    height: m.m,
                    margin: EdgeInsets.only(top: m.xs),
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (!last)
                    Expanded(
                      child: Container(width: 3, color: scheme.outlineVariant),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(width: m.m),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : m.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.at.formatTime(context), style: text.bodyMedium),
                  Text(event.stage.label(l), style: text.titleLarge),
                  if (riskChanged) ...[
                    SizedBox(height: m.s),
                    _RiskBadge(event.risk),
                  ],
                  for (final quote in event.quotes) ...[
                    SizedBox(height: m.s),
                    QuoteBlock(quote: quote),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Never red: red is the Warning's alone.
class _RiskBadge extends StatelessWidget {
  const _RiskBadge(this.risk);

  final Risk risk;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final (label, tone, icon) = switch (risk) {
      Risk.low => (
        l.familyTimelineRiskLow,
        BadgeTone.genuine,
        Icons.check_circle_outline,
      ),
      Risk.medium => (
        l.familyTimelineRiskMedium,
        BadgeTone.caution,
        Icons.info_outline,
      ),
      Risk.high => (
        l.familyTimelineRiskHigh,
        BadgeTone.caution,
        Icons.warning_amber,
      ),
    };
    return StatusBadge(label: label, tone: tone, icon: icon);
  }
}
