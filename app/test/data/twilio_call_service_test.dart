import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/core/haptics/fake_buzzer.dart';
import 'package:jaga/data/models/call_snapshot.dart';
import 'package:jaga/data/models/stage_update.dart';
import 'package:jaga/data/repositories/call_repository.dart';
import 'package:jaga/data/repositories/call_risk_repository.dart';
import 'package:jaga/data/services/attention_service.dart';
import 'package:jaga/data/services/stage_stream_service.dart';
import 'package:jaga/data/services/twilio_call_service.dart';
import 'package:jaga/data/services/voice_token_service.dart';
import 'package:jaga/debug/fixtures/stage_update_fixtures.dart';
import 'package:jaga/features/warning/view_models/warning_view_model.dart';
import 'package:twilio_voice/twilio_voice.dart';

final _t0 = DateTime.utc(2026, 11, 1, 10);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late StreamController<CallEvent> events;
  late TwilioCallService service;
  final seen = <CallSnapshot>[];
  var clock = _t0;

  setUp(() {
    events = StreamController<CallEvent>.broadcast(sync: true);
    seen.clear();
    clock = _t0;
    service = TwilioCallService(
      fcmToken: () async => 'fcm',
      events: events.stream,
      activeCall: () => ActiveCall(
        from: '+60326101599',
        to: 'client:jaga',
        callDirection: CallDirection.incoming,
        customParams: {'callId': 'c-1'},
      ),
      now: () => clock,
    );
    service.snapshots.listen(seen.add);
  });

  tearDown(() async {
    await service.dispose();
    await events.close();
  });

  List<CallPhase> play(List<CallEvent> list) {
    for (final e in list) {
      events.add(e);
    }
    return [for (final s in seen) s.phase];
  }

  test('ring, answer, connect, end: ringing, connecting, active, ended', () {
    final phases = play([
      CallEvent.incoming,
      CallEvent.answer,
      CallEvent.connected,
      CallEvent.callEnded,
    ]);
    expect(phases, [
      CallPhase.ringing,
      CallPhase.connecting,
      CallPhase.active,
      CallPhase.ended,
    ]);
    expect(seen[1].callId, 'c-1');
    expect(seen[2].connectedAt, _t0);
    expect(seen.last.endedAt, _t0);
  });

  test('answered but ended before connecting is failed', () {
    expect(play([CallEvent.answer, CallEvent.callEnded]), [
      CallPhase.connecting,
      CallPhase.failed,
    ]);
  });

  test('a call that rang and was declined or missed shows nothing', () {
    expect(play([CallEvent.incoming, CallEvent.declined]), [
      CallPhase.ringing,
      CallPhase.idle,
    ]);
    expect(
      play([CallEvent.incoming, CallEvent.callEnded]).last,
      CallPhase.idle,
    );
  });

  test('audio dropping and returning keeps the first connect time', () {
    play([CallEvent.answer, CallEvent.connected]);
    clock = _t0.add(const Duration(seconds: 30));
    final phases = play([CallEvent.reconnecting, CallEvent.reconnected]);
    expect(phases.skip(2), [CallPhase.reconnecting, CallPhase.active]);
    expect(seen.last.connectedAt, _t0);
  });

  test('mute and speaker events set the flags; the answer starts both off', () {
    play([CallEvent.incoming, CallEvent.speakerOn]);
    expect(seen.last.speakerOn, isTrue); // the plugin turns it on at ring
    play([CallEvent.answer, CallEvent.connected, CallEvent.mute]);
    expect(seen.last.muted, isTrue);
    expect(seen.last.speakerOn, isFalse);
    play([CallEvent.unmute, CallEvent.speakerOn]);
    expect(seen.last.muted, isFalse);
    expect(seen.last.speakerOn, isTrue);
    play([CallEvent.speakerOff]);
    expect(seen.last.speakerOn, isFalse);
  });

  test('a late ring while the call is live changes nothing', () {
    play([CallEvent.answer, CallEvent.connected]);
    final before = seen.length;
    play([CallEvent.ringing]);
    expect(seen.length, before);
    expect(seen.last.phase, CallPhase.active);
  });

  test('a repeated call end keeps ended', () {
    play([CallEvent.answer, CallEvent.connected, CallEvent.callEnded]);
    final before = seen.length;
    play([CallEvent.callEnded]);
    expect(seen.length, before);
    expect(seen.last.phase, CallPhase.ended);
  });

  group('answered from the ring screen: only a Connected without params', () {
    late StreamController<CallEvent> plugin;
    late TwilioCallService ringScreen;
    var listens = 0;
    Map<String, dynamic>? params;
    final got = <CallSnapshot>[];

    setUp(() {
      listens = 0;
      params = null;
      got.clear();
      plugin = StreamController<CallEvent>.broadcast(
        sync: true,
        onListen: () => listens++,
      );
      ringScreen = TwilioCallService(
        fcmToken: () async => 'fcm',
        events: plugin.stream,
        activeCall: () => ActiveCall(
          from: '+60326101599',
          to: 'client:jaga',
          callDirection: CallDirection.incoming,
          customParams: params,
        ),
        now: () => clock,
      );
      ringScreen.snapshots.listen(got.add);
    });

    tearDown(() async {
      await ringScreen.dispose();
      await plugin.close();
    });

    test(
      're-listens once and takes the callId from the re-emitted Connected',
      () async {
        plugin.add(CallEvent.connected);
        expect(got.single.callId, isNull);
        await pumpEventQueue();
        expect(listens, 2);

        // The plugin's re-emitted Connected carries the custom params.
        params = {'callId': 'c-9'};
        plugin.add(CallEvent.connected);
        expect(got.last.phase, CallPhase.active);
        expect(got.last.callId, 'c-9');
        expect(got.last.connectedAt, _t0);
      },
    );

    test(
      'no callId after re-listening (Fake path): no second re-listen',
      () async {
        plugin.add(CallEvent.connected);
        await pumpEventQueue();
        plugin.add(CallEvent.connected);
        await pumpEventQueue();
        expect(listens, 2);
        expect(got.last.callId, isNull);

        // The next call gets its own re-listen.
        plugin.add(CallEvent.callEnded);
        plugin.add(CallEvent.connected);
        await pumpEventQueue();
        expect(listens, 3);
      },
    );

    test('a call event during the start-up read keeps the callId, so the '
        'stage stream stays open and its updates show', () async {
      const channel = MethodChannel('twilio_voice/messages');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final muted = Completer<bool>();
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'isOnCall') return true;
        if (call.method == 'isMuted') return muted.future;
        return false;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      final stages = FakeStageStreamService();
      final repo = CallRepository(
        service: ringScreen,
        tokens: FakeVoiceTokenService(),
        stageStream: stages,
      );
      final warning = WarningViewModel(
        repository: CallRiskRepository(stages),
        buzzer: FakeBuzzer(),
        attention: FakeAttentionService(),
      );
      addTearDown(() {
        warning.dispose();
        repo.dispose();
        stages.dispose();
      });

      // The app starts mid-call: current() is waiting on isMuted when the
      // plugin's buffered and re-emitted Connected events arrive.
      final watching = repo.watch();
      await pumpEventQueue();
      plugin.add(CallEvent.connected);
      await pumpEventQueue();
      params = {'callId': 'c-9'};
      plugin.add(CallEvent.connected);
      expect(stages.connectedCalls, ['c-9']);

      muted.complete(false);
      await watching;
      expect(repo.snapshot.value.callId, 'c-9');
      expect(stages.closeCount, 0);

      // No call event from here on: the stage update alone shows Caution.
      stages.emit(StageUpdate.parse(stageMedium));
      expect(warning.state.layer, WarningLayer.caution);
    });

    test('dispose during a re-listen does not listen again', () async {
      plugin.add(CallEvent.connected);
      await ringScreen.dispose();
      await pumpEventQueue();
      expect(listens, 1);
      expect(plugin.hasListener, isFalse);
    });
  });

  test('events that mean nothing here change nothing', () {
    final before = seen.length;
    play([CallEvent.log, CallEvent.permission, CallEvent.hold]);
    expect(seen.length, before);
  });
}
