import 'package:flutter/material.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/big_button.dart';
import '../../../core/widgets/role_badge.dart';
import '../../../core/widgets/screen_frame.dart';
import '../../../data/models/alerted_call.dart';
import '../../../data/models/family_alert.dart';
import '../view_models/copilot_home_view_model.dart';
import '../view_models/load_status.dart';
import '../view_models/stage_timeline_view_model.dart';
import 'widgets/home_call_tile.dart';

/// Every alerted call of the last 30 days, live ones first.
class CopilotCallsScreen extends StatelessWidget {
  const CopilotCallsScreen({
    super.key,
    required this.vm,
    required this.timelineFor,
    required this.openAlert,
  });

  final CopilotHomeViewModel vm;
  final StageTimelineViewModel Function(AlertedCall call) timelineFor;
  final void Function(FamilyAlert alert) openAlert;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = context.metrics;
    final text = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) => ScreenFrame(
        role: const RoleBadge.family(),
        title: l.familyCallsTitle,
        // "Panggilan yang dimaklumkan" splits mid-word in headlineMedium at x2.0.
        titleStyle: text.titleLarge,
        body: switch (vm.status) {
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
          LoadStatus.loaded when vm.calls.isEmpty => Text(
            l.familyCallsEmpty,
            style: text.bodyLarge,
          ),
          LoadStatus.loaded => Column(
            children: [
              for (final call in vm.calls)
                HomeCallTile(
                  vm: vm,
                  call: call,
                  timelineFor: timelineFor,
                  openAlert: openAlert,
                ),
            ],
          ),
        },
      ),
    );
  }
}
