import 'package:flutter/material.dart';

import '../../core/haptics/fake_buzzer.dart';
import '../../data/repositories/call_risk_repository.dart';
import '../../data/services/attention_service.dart';
import '../../data/services/call_service.dart';
import '../../data/services/stage_stream_service.dart';
import '../../features/warning/view_models/warning_view_model.dart';
import '../demo_call_screen.dart';
import '../gallery_entry.dart';

const _serverUrl = String.fromEnvironment('JAGA_SERVER_URL');

/// Paste the CallSid of a scripted call on a local server and watch its Caution
/// then Warning over the demo call. [stream] is injected by tests.
class LiveCallFollower extends StatefulWidget {
  const LiveCallFollower({super.key, this.stream, this.serverUrl = _serverUrl});

  final StageStreamService? stream;
  final String serverUrl;

  @override
  State<LiveCallFollower> createState() => _LiveCallFollowerState();
}

class _LiveCallFollowerState extends State<LiveCallFollower> {
  final _callId = TextEditingController();
  final _service = FakeCallService(DemoCallScreen.active());
  late final StageStreamService? _stream =
      widget.stream ??
      (widget.serverUrl.isEmpty
          ? null
          : WebSocketStageStreamService(Uri.parse(widget.serverUrl)));
  WarningViewModel? _vm;

  void _follow() {
    final id = _callId.text.trim();
    final stream = _stream;
    if (id.isEmpty || stream == null) return;
    _vm?.dispose();
    stream.connect(id);
    setState(
      () => _vm = WarningViewModel(
        repository: CallRiskRepository(stream, callId: id),
        buzzer: FakeBuzzer(),
        attention: FakeAttentionService(),
      ),
    );
  }

  void _stop() {
    _stream?.close();
    _vm?.dispose();
    setState(() => _vm = null);
  }

  @override
  void dispose() {
    _vm?.dispose();
    _stream?.close();
    _service.dispose();
    _callId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = _vm;
    if (_stream == null) {
      return const Center(
        child: Text(
          'Set JAGA_SERVER_URL with --dart-define (emulator: http://10.0.2.2:8000).',
        ),
      );
    }
    if (vm != null) {
      return Stack(
        children: [
          DemoCallScreen(warningVm: vm, service: _service),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: TextButton(onPressed: _stop, child: const Text('Stop')),
            ),
          ),
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: _callId,
            decoration: const InputDecoration(labelText: 'Call id (CallSid)'),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _follow, child: const Text('Follow')),
        ],
      ),
    );
  }
}

List<GalleryEntry> liveCallEntries() => [
  GalleryEntry(
    feature: 'warning',
    state: 'Follow a live call',
    build: (_) => const LiveCallFollower(),
  ),
];
