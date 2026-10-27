import 'package:flutter/material.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/big_button.dart';
import '../../../core/widgets/screen_frame.dart';
import '../../../core/widgets/view_model_host.dart';
import '../../../data/models/alerted_call.dart';
import '../../../data/services/copilot_pause_service.dart';
import '../view_models/clear_pause_view_model.dart';
import '../view_models/copilot_home_view_model.dart';
import '../view_models/copilot_settings_view_model.dart';
import '../view_models/load_status.dart';
import '../view_models/stage_timeline_view_model.dart';
import 'copilot_settings_screen.dart';
import 'stage_timeline_screen.dart';
import 'widgets/alerted_call_tile.dart';
import 'widgets/clear_pause_sheet.dart';
import 'widgets/protected_person_card.dart';

/// The family co-pilot's home: the protected user, Jaga Pause, and the calls
/// the family was alerted about.
class CopilotHomeScreen extends StatelessWidget {
  const CopilotHomeScreen({
    super.key,
    required this.vm,
    required this.pause,
    required this.timelineFor,
    required this.createSettings,
  });

  final CopilotHomeViewModel vm;
  final CopilotPauseService pause;
  final StageTimelineViewModel Function(AlertedCall call) timelineFor;
  final CopilotSettingsViewModel Function() createSettings;

  Future<void> _clearPause(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final cleared = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ViewModelHost(
        create: () =>
            ClearPauseViewModel(personName: vm.person.name, pause: pause),
        builder: (_, sheetVm) => ClearPauseSheet(vm: sheetVm),
      ),
    );
    if (cleared != true) return;
    vm.load();
    messenger.showSnackBar(SnackBar(content: Text(l.familyPauseCleared)));
  }

  Future<void> _openTimeline(BuildContext context, AlertedCall call) async {
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ViewModelHost(
          create: () => timelineFor(call),
          builder: (_, timelineVm) => StageTimelineScreen(vm: timelineVm),
        ),
      ),
    );
    if (deleted == true) vm.load();
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ViewModelHost(
          create: createSettings,
          builder: (_, settingsVm) => CopilotSettingsScreen(vm: settingsVm),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = context.metrics;
    final text = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) => ScreenFrame(
        appBar: AppBar(
          actions: [
            PopupMenuButton<void>(
              itemBuilder: (_) => [
                PopupMenuItem<void>(
                  onTap: () => _openSettings(context),
                  child: Text(l.settingsTitle),
                ),
              ],
            ),
          ],
        ),
        title: l.appTitle,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProtectedPersonCard(
              name: vm.person.name,
              pauseActive: vm.pauseActive,
              onClearPause: () => _clearPause(context),
            ),
            SizedBox(height: m.xl),
            Semantics(
              header: true,
              child: Text(l.familyCallsTitle, style: text.titleLarge),
            ),
            SizedBox(height: m.m),
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
              LoadStatus.loaded when vm.calls.isEmpty => Text(
                l.familyCallsEmpty,
                style: text.bodyLarge,
              ),
              LoadStatus.loaded => Column(
                children: [
                  for (final call in vm.calls)
                    Padding(
                      padding: EdgeInsets.only(bottom: m.s),
                      child: AlertedCallTile(
                        call: call,
                        onTap: () => _openTimeline(context, call),
                      ),
                    ),
                ],
              ),
            },
          ],
        ),
      ),
    );
  }
}
