import 'package:flutter/material.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/big_button.dart';
import '../../../core/widgets/jaga_wordmark.dart';
import '../../../core/widgets/role_badge.dart';
import '../../../core/widgets/screen_frame.dart';
import '../../../core/widgets/view_model_host.dart';
import '../../../data/models/alerted_call.dart';
import '../../../data/models/family_alert.dart';
import '../view_models/clear_pause_view_model.dart';
import '../view_models/copilot_home_view_model.dart';
import '../view_models/load_status.dart';
import '../view_models/stage_timeline_view_model.dart';
import 'widgets/clear_pause_sheet.dart';
import 'widgets/home_call_tile.dart';
import 'widgets/protected_person_card.dart';

/// The family co-pilot's home: the protected user, Jaga Pause, and the calls
/// the family was alerted about.
class CopilotHomeScreen extends StatelessWidget {
  const CopilotHomeScreen({
    super.key,
    required this.vm,
    required this.createClearPause,
    required this.timelineFor,
    required this.openAlert,
    required this.onSeeAllCalls,
  });

  final CopilotHomeViewModel vm;
  final ClearPauseViewModel Function() createClearPause;
  final StageTimelineViewModel Function(AlertedCall call) timelineFor;

  /// Opens the family alert screen (the shell builds that route).
  final void Function(FamilyAlert alert) openAlert;

  /// Switches to the Calls tab.
  final VoidCallback onSeeAllCalls;

  Future<void> _clearPause(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final cleared = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      // The sheet can't be dragged shut mid-request; Back and a tap outside
      // are guarded by its PopScope.
      enableDrag: false,
      builder: (_) => ViewModelHost(
        create: createClearPause,
        builder: (_, sheetVm) => ClearPauseSheet(vm: sheetVm),
      ),
    );
    if (cleared == true) {
      vm.markPauseCleared();
      messenger.showSnackBar(SnackBar(content: Text(l.familyPauseCleared)));
    }
    vm.load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = context.metrics;
    final text = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) => ScreenFrame(
        role: const RoleBadge.family(),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The wordmark hides itself from TalkBack: this is the header.
            Semantics(
              header: true,
              label: l.appTitle,
              child: JagaWordmark(
                size: JagaWordmarkSize.display,
                color: context.jagaColors.guarded,
              ),
            ),
            SizedBox(height: m.l),
            ProtectedPersonCard(
              name: vm.person.name,
              pauseActive: vm.status == LoadStatus.loaded && vm.pauseActive,
              onClearPause: () => _clearPause(context),
            ),
            SizedBox(height: m.xl),
            switch (vm.status) {
              LoadStatus.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              LoadStatus.error => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l.familyCallsError, style: text.bodyLarge),
                  SizedBox(height: m.m),
                  BigButton(
                    tone: BigButtonTone.quiet,
                    label: l.commonTryAgain,
                    onPressed: vm.load,
                  ),
                ],
              ),
              LoadStatus.loaded => _calls(context),
            },
          ],
        ),
      ),
    );
  }

  /// Every live call; with none, the last ended one; then the way to all of them.
  Widget _calls(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = context.metrics;
    final text = Theme.of(context).textTheme;
    final live = vm.liveCalls;
    final last = vm.lastEnded;
    HomeCallTile tile(AlertedCall call) => HomeCallTile(
      vm: vm,
      call: call,
      timelineFor: timelineFor,
      openAlert: openAlert,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final call in live) tile(call),
        if (live.isEmpty && last != null) ...[
          Semantics(
            header: true,
            child: Text(l.familyHomeLastCall, style: text.titleLarge),
          ),
          SizedBox(height: m.m),
          tile(last),
        ],
        if (live.isEmpty && last == null)
          Text(l.familyCallsEmpty, style: text.bodyLarge),
        if (vm.calls.isNotEmpty)
          TextButton(
            onPressed: onSeeAllCalls,
            child: Text(l.familyHomeSeeAllCalls),
          ),
      ],
    );
  }
}
