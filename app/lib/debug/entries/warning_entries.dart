import 'package:flutter/material.dart';

import '../../core/haptics/fake_buzzer.dart';
import '../../data/models/stage_update.dart';
import '../../data/repositories/call_risk_repository.dart';
import '../../data/services/attention_service.dart';
import '../../data/services/stage_stream_service.dart';
import '../../features/warning/view_models/warning_view_model.dart';
import '../fixtures/stage_update_extended_fixtures.dart';
import '../fixtures/stage_update_fixtures.dart';
import '../gallery_entry.dart';
import '../placeholder_call_screen.dart';

typedef _Script = void Function(FakeStageStreamService s, WarningViewModel vm);

/// Runs a script against a fresh view model, then shows the placeholder call screen.
class _WarningDemo extends StatefulWidget {
  const _WarningDemo(this.script);

  final _Script script;

  @override
  State<_WarningDemo> createState() => _WarningDemoState();
}

class _WarningDemoState extends State<_WarningDemo> {
  final _stream = FakeStageStreamService();
  late final WarningViewModel _vm = WarningViewModel(
    repository: CallRiskRepository(_stream),
    buzzer: FakeBuzzer(),
    attention: FakeAttentionService(),
  );

  @override
  void initState() {
    super.initState();
    widget.script(_stream, _vm);
  }

  @override
  void dispose() {
    _vm.dispose();
    _stream.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PlaceholderCallScreen(vm: _vm);
}

GalleryEntry _entry(String state, _Script script) => GalleryEntry(
  feature: 'warning',
  state: state,
  build: (_) => _WarningDemo(script),
);

List<GalleryEntry> warningEntries() {
  StageUpdate u(String raw) => StageUpdate.parse(raw);
  return [
    _entry('low', (s, _) => s.emit(u(stageLow))),
    _entry('medium', (s, _) => s.emit(u(stageMedium))),
    _entry('high', (s, _) => s.emit(u(extHigh))),
    _entry('high-credentials', (s, _) => s.emit(u(extHighCredentials))),
    _entry('high-english-only', (s, _) => s.emit(u(extHighEnglishOnly))),
    _entry('high-long-text', (s, _) => s.emit(u(extHighLongText))),
    _entry('high-no-number', (s, _) => s.emit(u(extHighNoNumber))),
    _entry('dismissed', (s, vm) {
      s.emit(u(extHigh));
      vm.dismiss();
    }),
    _entry('stepped-down', (s, _) {
      s.emit(u(extHigh));
      s.emit(u(stageMedium));
    }),
    _entry('reconnecting-high', (s, _) {
      s.emit(u(extHigh));
      s.setConnected(false);
    }),
    _entry('reconnecting-medium', (s, _) {
      s.emit(u(stageMedium));
      s.setConnected(false);
    }),
  ];
}
