import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/core/haptics/fake_buzzer.dart';
import 'package:jaga/data/models/call_snapshot.dart';
import 'package:jaga/data/models/stage_update.dart';
import 'package:jaga/data/repositories/call_repository.dart';
import 'package:jaga/data/repositories/call_risk_repository.dart';
import 'package:jaga/data/services/attention_service.dart';
import 'package:jaga/data/services/call_service.dart';
import 'package:jaga/data/services/stage_stream_service.dart';
import 'package:jaga/data/services/voice_token_service.dart';
import 'package:jaga/debug/fixtures/stage_update_fixtures.dart';
import 'package:jaga/features/warning/view_models/warning_view_model.dart';

const _fast = [Duration(milliseconds: 10)];

/// A loopback server standing in for `/calls/{id}/stages`.
class _Server {
  late final HttpServer http;
  final sockets = <WebSocket>[];
  final paths = <String>[];
  int? rejectWith;
  int rejectTimes = 0; // reject this many requests, then upgrade

  Future<void> start() async {
    http = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    http.listen((req) async {
      paths.add(req.uri.path);
      if (rejectTimes > 0) {
        rejectTimes--;
        req.response.statusCode = HttpStatus.serviceUnavailable;
        await req.response.close();
        return;
      }
      if (rejectWith != null) {
        req.response.statusCode = rejectWith!;
        await req.response.close();
        return;
      }
      sockets.add(await WebSocketTransformer.upgrade(req));
    });
  }

  Uri get url => Uri.parse('http://127.0.0.1:${http.port}');

  Future<WebSocket> nextSocket(int count) async {
    while (sockets.length < count) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    return sockets[count - 1];
  }
}

Future<void> _until(bool Function() ok) async {
  for (var i = 0; i < 400 && !ok(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(ok(), isTrue);
}

void main() {
  late _Server server;
  late WebSocketStageStreamService service;
  late List<StageUpdate> got;

  setUp(() async {
    server = _Server();
    await server.start();
    service = WebSocketStageStreamService(server.url, backoff: _fast);
    got = [];
    service.updates.listen(got.add);
  });

  tearDown(() async {
    service.close();
    await server.http.close(force: true);
  });

  test('receives updates and ignores a malformed message', () async {
    service.connect('CA1');
    final ws = await server.nextSocket(1);
    expect(server.paths.single, '/calls/CA1/stages');
    ws.add('not json');
    ws.add(stageMedium);
    ws.add(stageHigh);
    await _until(() => got.length == 2);
    expect(got.map((u) => u.risk), [Risk.medium, Risk.high]);
  });

  test('reconnects after a drop and skips the replayed updates', () async {
    service.connect('CA1');
    var ws = await server.nextSocket(1);
    ws.add(stageMedium);
    await _until(() => got.length == 1);
    await ws.close(WebSocketStatus.goingAway);
    await _until(() => !service.connected.value);
    ws = await server.nextSocket(2);
    ws.add(stageMedium); // replay from the start
    ws.add(stageHigh);
    await _until(() => got.length == 2);
    expect(got.map((u) => u.risk), [Risk.medium, Risk.high]);
    expect(service.connected.value, isTrue);
  });

  test('a refused handshake (unknown call) gives up', () async {
    server.rejectWith = HttpStatus.forbidden;
    service.connect('nope');
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(server.paths, hasLength(WebSocketStageStreamService.maxRefusals));
  });

  test('a 503 during a deploy retries and then connects', () async {
    server.rejectTimes = 1;
    service.connect('CA1');
    final ws = await server.nextSocket(1);
    ws.add(stageMedium);
    await _until(() => got.length == 1);
    expect(server.paths, hasLength(2));
  });

  test('close() cancels a pending backoff', () async {
    final slow = WebSocketStageStreamService(
      server.url,
      backoff: const [Duration(seconds: 30)],
    );
    server.rejectTimes = 1;
    slow.connect('CA1');
    await _until(() => server.paths.length == 1);
    slow.close();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(server.paths, hasLength(1));
  });

  test('a call id is encoded in the path', () async {
    service.connect('a/b');
    await server.nextSocket(1);
    expect(server.paths.single, '/calls/a%2Fb/stages');
  });

  test('close code 1008 stops without retry', () async {
    service.connect('CA1');
    final ws = await server.nextSocket(1);
    await ws.close(WebSocketStatus.policyViolation);
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(server.sockets, hasLength(1));
  });

  test('a normal close (call ended) stops; close() ends the stream', () async {
    service.connect('CA1');
    final ws = await server.nextSocket(1);
    await ws.close(WebSocketStatus.normalClosure);
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(server.sockets, hasLength(1));

    service.connect('CA2');
    await server.nextSocket(2);
    service.close();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(server.sockets, hasLength(2));
  });

  test(
    'the live call drives the stream; the Warning follows the script',
    () async {
      final fakeStream = FakeStageStreamService();
      final calls = FakeCallService();
      final repo = CallRepository(
        service: calls,
        tokens: FakeVoiceTokenService(),
        stageStream: fakeStream,
      );
      await repo.watch();

      calls.emit(const CallSnapshot(phase: CallPhase.active));
      expect(fakeStream.connectedCalls, isEmpty);

      calls.emit(const CallSnapshot(phase: CallPhase.active, callId: 'CA1'));
      calls.emit(
        const CallSnapshot(phase: CallPhase.reconnecting, callId: 'CA1'),
      );
      expect(fakeStream.connectedCalls, ['CA1']);

      final vm = WarningViewModel(
        repository: CallRiskRepository(fakeStream),
        buzzer: FakeBuzzer(),
        attention: FakeAttentionService(),
      );
      fakeStream.emit(StageUpdate.parse(stageMedium));
      expect(vm.state.layer, WarningLayer.caution);
      fakeStream.emit(StageUpdate.parse(stageHigh));
      expect(vm.state.layer, WarningLayer.warning);

      calls.emit(const CallSnapshot(phase: CallPhase.ended, callId: 'CA1'));
      expect(fakeStream.closeCount, 1);
      vm.dispose();
      repo.dispose();
      fakeStream.dispose();
    },
  );
}
