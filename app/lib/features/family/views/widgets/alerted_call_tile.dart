import 'package:flutter/material.dart';

import '../../../../core/l10n/date_text.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/stage_progress_bar.dart';
import '../../../../data/models/alerted_call.dart';

/// One alerted call in the home list: when, who they claimed to be, how far it got.
class AlertedCallTile extends StatelessWidget {
  const AlertedCallTile({super.key, required this.call, required this.onTap});

  final AlertedCall call;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m = context.metrics;
    final text = Theme.of(context).textTheme;
    final agency = call.claimedAgency;
    final shape = BorderRadius.circular(m.radiusMedium);
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: shape,
      child: InkWell(
        borderRadius: shape,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: EdgeInsets.all(m.m),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        call.at.formatDayAndTime(context),
                        style: text.titleLarge,
                      ),
                      if (agency != null) Text(agency, style: text.bodyMedium),
                      SizedBox(height: m.s),
                      StageProgressBar(stage: call.stage, compact: true),
                    ],
                  ),
                ),
                SizedBox(width: m.s),
                const ExcludeSemantics(child: Icon(Icons.chevron_right)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
