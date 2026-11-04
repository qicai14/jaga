import 'package:flutter/material.dart';

import '../../../../core/l10n/date_text.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/stage_progress_bar.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../data/models/alerted_call.dart';

/// One alerted call in the home list: when, who they claimed to be, how far it got.
class AlertedCallTile extends StatelessWidget {
  const AlertedCallTile({
    super.key,
    required this.call,
    required this.onTap,
    this.opensAlert = false,
  });

  final AlertedCall call;
  final VoidCallback onTap;

  /// Tapping opens the family alert, not the timeline (a screen reader hint).
  final bool opensAlert;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.jagaColors;
    final m = context.metrics;
    final text = Theme.of(context).textTheme;
    final agency = call.claimedAgency;
    final shape = BorderRadius.circular(m.radiusMedium);
    return Semantics(
      button: true,
      hint: call.live && opensAlert ? l.familyCallLiveOpen : null,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainer,
        // Amber fill belongs to the name band, so the marker is only the edge.
        shape: call.live
            ? RoundedRectangleBorder(
                borderRadius: shape,
                side: BorderSide(color: c.cautionEdge, width: 3),
              )
            : RoundedRectangleBorder(borderRadius: shape),
        child: InkWell(
          borderRadius: shape,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: EdgeInsets.all(m.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Above the row, not beside the chevron: the badge gets the
                  // tile's full width, so "Sedang berlangsung" wraps at the space.
                  if (call.live) ...[
                    StatusBadge(
                      label: l.familyCallLiveNow,
                      tone: BadgeTone.caution,
                      icon: Icons.phone_in_talk,
                    ),
                    SizedBox(height: m.xs),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              call.at.formatDayAndTime(context),
                              style: text.titleLarge,
                            ),
                            if (agency != null)
                              Text(agency, style: text.bodyMedium),
                            SizedBox(height: m.s),
                            StageProgressBar(stage: call.stage, compact: true),
                          ],
                        ),
                      ),
                      SizedBox(width: m.s),
                      const ExcludeSemantics(child: Icon(Icons.chevron_right)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
