import 'package:flutter/material.dart';

import '../../data/models/stage.dart';
import '../l10n/gen/app_localizations.dart';
import '../theme/theme_context.dart';

const _totalSteps = 7;

extension StageLabels on Stage {
  /// 1..7 for pretext..credentials, 0 for none.
  int get step => index;

  /// Plain-word label; empty for [Stage.none].
  String label(AppLocalizations l) => switch (this) {
        Stage.none => '',
        Stage.pretext => l.stageLabelPretext,
        Stage.authority => l.stageLabelAuthority,
        Stage.fear => l.stageLabelFear,
        Stage.isolation => l.stageLabelIsolation,
        Stage.handoff => l.stageLabelHandoff,
        Stage.money => l.stageLabelMoney,
        Stage.credentials => l.stageLabelCredentials,
      };
}

/// The 7-step scam-script bar with a plain-word label under it.
class StageProgressBar extends StatelessWidget {
  const StageProgressBar({super.key, required this.stage, this.compact = false});

  final Stage stage;

  /// Thinner bar, no label (for list rows).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final m = context.metrics;
    final label = stage.label(l);
    final height = compact ? 6.0 : 12.0;

    return Semantics(
      container: true,
      label: stage == Stage.none
          ? null
          : l.stageStepSemantics(stage.step, _totalSteps, label),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (var i = 1; i <= _totalSteps; i++) ...[
                  if (i > 1) const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      height: height,
                      decoration: BoxDecoration(
                        color: i <= stage.step ? scheme.primary : scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(m.radiusPill),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (!compact && label.isNotEmpty) ...[
              SizedBox(height: m.s),
              Text(label, style: Theme.of(context).textTheme.labelMedium),
            ],
          ],
        ),
      ),
    );
  }
}
