import 'package:flutter/material.dart';

import '../../core/haptics/fake_buzzer.dart';
import '../../data/models/call_snapshot.dart';
import '../../data/repositories/call_risk_repository.dart';
import '../../data/services/attention_service.dart';
import '../../data/services/call_service.dart';
import '../../data/services/stage_stream_service.dart';
import '../../features/warning/view_models/warning_view_model.dart';
import '../demo_call_screen.dart';
import '../gallery_entry.dart';

/// One call state on the in-call screen, no Warning.
class _CallDemo extends StatefulWidget {
  const _CallDemo(this.snapshot);

  final CallSnapshot snapshot;

  @override
  State<_CallDemo> createState() => _CallDemoState();
}

class _CallDemoState extends State<_CallDemo> {
  final _stream = FakeStageStreamService();
  late final _service = FakeCallService(widget.snapshot);
  late final _warning = WarningViewModel(
    repository: CallRiskRepository(_stream),
    buzzer: FakeBuzzer(),
    attention: FakeAttentionService(),
  );

  @override
  void dispose() {
    _warning.dispose();
    _stream.dispose();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      DemoCallScreen(warningVm: _warning, service: _service);
}

List<GalleryEntry> callEntries() {
  final active = DemoCallScreen.active();
  GalleryEntry entry(String state, CallSnapshot s) =>
      GalleryEntry(feature: 'call', state: state, build: (_) => _CallDemo(s));
  final end = active.connectedAt!.add(const Duration(minutes: 2, seconds: 14));
  return [
    entry(
      'connecting',
      const CallSnapshot(
        phase: CallPhase.connecting,
        callerLabel: DemoCallScreen.callerNumber,
      ),
    ),
    entry('active', active),
    entry('muted', active.copyWith(muted: true)),
    entry('speaker-on', active.copyWith(speakerOn: true)),
    entry('reconnecting', active.copyWith(phase: CallPhase.reconnecting)),
    entry('ended', active.copyWith(phase: CallPhase.ended, endedAt: end)),
    entry(
      'failed',
      const CallSnapshot(
        phase: CallPhase.failed,
        callerLabel: DemoCallScreen.callerNumber,
      ),
    ),
  ];
}
