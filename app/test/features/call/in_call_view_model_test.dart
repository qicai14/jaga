import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/data/models/call_snapshot.dart';
import 'package:jaga/data/repositories/call_repository.dart';
import 'package:jaga/data/services/call_service.dart';
import 'package:jaga/data/services/call_ui_service.dart';
import 'package:jaga/data/services/voice_token_service.dart';
import 'package:jaga/features/call/view_models/in_call_view_model.dart';

final _start = DateTime.utc(2026, 11, 1, 10);

void main() {
  late FakeCallService service;
  late FakeCallUiService ui;
  late CallRepository repo;
  late InCallViewModel vm;
  var now = _start;

  Future<void> open(CallSnapshot snapshot) async {
    service = FakeCallService(snapshot);
    ui = FakeCallUiService();
    repo = CallRepository(service: service, tokens: FakeVoiceTokenService());
    await repo.watch();
    vm = InCallViewModel(repository: repo, callUi: ui, now: () => now);
  }

  /// Ends the test: the view model's one-second timer must not outlive it.
  void close() {
    vm.dispose();
    repo.dispose();
  }

  setUp(() => now = _start.add(const Duration(minutes: 2, seconds: 14)));

  CallSnapshot active() =>
      CallSnapshot(phase: CallPhase.active, connectedAt: _start);

  testWidgets('elapsed runs while active and stops at the end', (tester) async {
    await open(active());
    expect(vm.elapsed, const Duration(minutes: 2, seconds: 14));
    now = now.add(const Duration(seconds: 3));
    expect(vm.elapsed, const Duration(minutes: 2, seconds: 17));

    service.emit(active().copyWith(phase: CallPhase.ended, endedAt: now));
    now = now.add(const Duration(minutes: 5));
    expect(vm.elapsed, const Duration(minutes: 2, seconds: 17));
    close();
  });

  testWidgets('controls need a connected call', (tester) async {
    await open(const CallSnapshot(phase: CallPhase.connecting));
    expect(vm.controlsEnabled, isFalse);
    service.emit(active());
    expect(vm.controlsEnabled, isTrue);
    close();
  });

  testWidgets('mute and speaker flip the other way and go to the service', (
    tester,
  ) async {
    await open(active());
    await vm.toggleMute();
    await vm.toggleSpeaker();
    expect(service.mutedCalls, [true]);
    expect(service.speakerCalls, [true]);
    await vm.toggleMute();
    expect(service.mutedCalls, [true, false]);
    close();
  });

  testWidgets(
    'the ear lock is held only with the speaker off and Jaga in front',
    (tester) async {
      await open(active());
      expect(ui.proximityLock, isTrue);
      vm.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(ui.proximityLock, isFalse);
      vm.didChangeAppLifecycleState(AppLifecycleState.resumed);
      expect(ui.proximityLock, isTrue);
      service.emit(active().copyWith(speakerOn: true));
      expect(ui.proximityLock, isFalse);
      service.emit(active().copyWith(phase: CallPhase.ended));
      expect(ui.proximityLock, isFalse);
      close();
    },
  );
}
