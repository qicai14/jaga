import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/view_model_host.dart';
import '../../../../data/models/alerted_call.dart';
import '../../../../data/models/family_alert.dart';
import '../../view_models/copilot_home_view_model.dart';
import '../../view_models/stage_timeline_view_model.dart';
import '../stage_timeline_screen.dart';
import 'alerted_call_tile.dart';

/// An [AlertedCallTile] on Home or Calls: a live call with a held alert opens
/// the alert, anything else its timeline (full-screen, over the tab bar).
class HomeCallTile extends StatelessWidget {
  const HomeCallTile({
    super.key,
    required this.vm,
    required this.call,
    required this.timelineFor,
    required this.openAlert,
  });

  final CopilotHomeViewModel vm;
  final AlertedCall call;
  final StageTimelineViewModel Function(AlertedCall call) timelineFor;
  final void Function(FamilyAlert alert) openAlert;

  Future<void> _openTimeline(BuildContext context) async {
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

  @override
  Widget build(BuildContext context) {
    final alert = call.live ? vm.heldAlert(call.callId) : null;
    return Padding(
      padding: EdgeInsets.only(bottom: context.metrics.s),
      child: AlertedCallTile(
        call: call,
        opensAlert: alert != null,
        onTap: () => alert == null ? _openTimeline(context) : openAlert(alert),
      ),
    );
  }
}
