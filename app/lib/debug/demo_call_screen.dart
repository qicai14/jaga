import 'package:flutter/material.dart';

import '../data/models/call_snapshot.dart';
import '../data/repositories/call_repository.dart';
import '../data/services/call_service.dart';
import '../data/services/call_ui_service.dart';
import '../data/services/voice_token_service.dart';
import '../features/call/view_models/in_call_view_model.dart';
import '../features/call/views/in_call_screen.dart';
import '../features/warning/view_models/warning_view_model.dart';

/// The real in-call screen on a scripted [FakeCallService], so the gallery and the
/// warning tests can see the Caution and Warning over it. Debug only.
class DemoCallScreen extends StatefulWidget {
  const DemoCallScreen({
    super.key,
    required this.warningVm,
    required this.service,
    this.callUi,
  });

  final WarningViewModel warningVm;
  final FakeCallService service;
  final CallUiService? callUi;

  static const callerNumber = '+60 3-2610 1599';

  /// A connected call, 2 minutes 14 seconds in.
  static CallSnapshot active() => CallSnapshot(
    phase: CallPhase.active,
    callerLabel: callerNumber,
    connectedAt: DateTime.now().subtract(
      const Duration(minutes: 2, seconds: 14),
    ),
  );

  @override
  State<DemoCallScreen> createState() => _DemoCallScreenState();
}

class _DemoCallScreenState extends State<DemoCallScreen> {
  late final _repository = CallRepository(
    service: widget.service,
    tokens: FakeVoiceTokenService(),
  );
  InCallViewModel? _vm;

  @override
  void initState() {
    super.initState();
    _repository.watch().then((_) {
      if (!mounted) return;
      setState(
        () => _vm = InCallViewModel(
          repository: _repository,
          callUi: widget.callUi ?? FakeCallUiService(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _vm?.dispose();
    _repository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = _vm;
    return vm == null
        ? const SizedBox.shrink()
        : InCallScreen(vm: vm, warningVm: widget.warningVm);
  }
}
