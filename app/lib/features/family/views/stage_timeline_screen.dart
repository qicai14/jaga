import 'package:flutter/material.dart';

import '../../../core/l10n/date_text.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/jaga_metrics.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/big_button.dart';
import '../../../core/widgets/screen_frame.dart';
import '../../../data/models/scam_hotline.dart';
import '../../../data/models/stage_update.dart';
import '../view_models/load_status.dart';
import '../view_models/stage_timeline_view_model.dart';
import 'widgets/timeline_event_row.dart';

/// What happened in one alerted call, step by step. The co-pilot may delete it.
/// Pops true when it was deleted.
class StageTimelineScreen extends StatelessWidget {
  const StageTimelineScreen({super.key, required this.vm});

  final StageTimelineViewModel vm;

  Future<void> _delete(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l.familyTimelineDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.familyTimelineDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final deleted = await vm.delete();
    if (deleted && context.mounted) navigator.pop(true);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          deleted ? l.familyTimelineDeleted : l.familyTimelineDeleteError,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = context.metrics;
    return ListenableBuilder(
      listenable: vm,
      // Leaving mid-delete would hide whether it worked.
      builder: (context, _) => PopScope(
        canPop: !vm.deleting,
        child: ScreenFrame(
          appBar: AppBar(
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: l.familyTimelineDelete,
                onPressed: vm.deleting ? null : () => _delete(context),
              ),
            ],
          ),
          // The title scrolls with the steps: a long title at large text must not
          // squeeze them against the pinned hotline button.
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  l.familyTimelineTitle(vm.call.at.formatDay(context)),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              SizedBox(height: m.m),
              _content(context, l, m),
            ],
          ),
          bottomAction: BigButton(
            icon: Icons.call,
            label: l.familyCallHotline(scamHotline),
            onPressed: vm.callHotline,
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, AppLocalizations l, JagaMetrics m) =>
      switch (vm.status) {
        LoadStatus.loading => const Center(child: CircularProgressIndicator()),
        LoadStatus.error => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.familyTimelineError,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: m.m),
            BigButton(
              tone: BigButtonTone.quiet,
              label: l.commonTryAgain,
              onPressed: vm.load,
            ),
          ],
        ),
        LoadStatus.loaded => Column(
          children: [
            for (final (i, event) in vm.events.indexed)
              TimelineEventRow(
                event: event,
                riskChanged:
                    event.risk != (i == 0 ? Risk.low : vm.events[i - 1].risk),
                last: i == vm.events.length - 1,
              ),
          ],
        ),
      };
}
