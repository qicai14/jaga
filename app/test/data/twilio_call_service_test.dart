import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/data/models/call_snapshot.dart';
import 'package:jaga/data/services/twilio_call_service.dart';
import 'package:twilio_voice/twilio_voice.dart';

final _t0 = DateTime.utc(2026, 11, 1, 10);

void main() {
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
