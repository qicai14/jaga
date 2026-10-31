import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jaga/data/models/stage.dart';
import 'package:jaga/data/services/copilot_pause_service.dart';
import 'package:jaga/data/services/network_exception.dart';
import 'package:jaga/data/services/timeline_service.dart';

String _fixture(String path) =>
    File('../contracts/fixtures/$path').readAsStringSync();

final _base = Uri.parse('https://jaga.test');
const _notFound = '{"detail":"Not Found"}';

void main() {
  late List<http.Request> sent;
  HttpTimelineService timeline(int status, [String body = '']) {
    sent = [];
    return HttpTimelineService(
      baseUrl: _base,
      token: 'tok',
      client: MockClient((req) async {
        sent.add(req);
        return http.Response(body, status);
      }),
    );
  }

  HttpCopilotPauseService pause(int status, [String body = '']) {
    sent = [];
    return HttpCopilotPauseService(
      baseUrl: _base,
      token: 'tok',
      client: MockClient((req) async {
        sent.add(req);
        return http.Response(body, status);
      }),
    );
  }

  group('HttpTimelineService', () {
    test('lists calls with the bearer header', () async {
      final calls = await timeline(
        200,
        _fixture('stage-timeline-list/two-calls-newest-first.json'),
      ).calls();
      expect(sent.single.url.path, '/timelines');
      expect(sent.single.headers['Authorization'], 'Bearer tok');
      expect(calls, hasLength(2));
      expect(calls.first.callId, 'call_01HZXB2R8T');
      expect(calls.first.stage, Stage.authority);
    });

    test('reads one timeline', () async {
      final events = await timeline(
        200,
        _fixture('stage-timeline/full-call.json'),
      ).events('call_1');
      expect(sent.single.url.path, '/timelines/call_1');
      expect(events, isNotEmpty);
    });

    test('a gone timeline has no events', () async {
      expect(await timeline(404, _notFound).events('x'), isEmpty);
    });

    test('delete sends DELETE; 204 succeeds, 404 is an error', () async {
      await timeline(204).delete('call_1');
      expect(sent.single.method, 'DELETE');
      expect(sent.single.url.path, '/timelines/call_1');
      expect(
        timeline(404, _notFound).delete('call_1'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('a call id is encoded in the path', () async {
      await timeline(200, '{"events":[]}').events('a/b');
      expect(sent.single.url.toString(), 'https://jaga.test/timelines/a%2Fb');
    });

    test('a malformed body throws NetworkException', () {
      expect(
        timeline(200, 'not json').calls(),
        throwsA(isA<NetworkException>()),
      );
      expect(
        timeline(200, '{"events":[{"stage":"nope"}]}').events('x'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('a refused list or a network failure throws NetworkException', () {
      expect(
        timeline(404, _notFound).calls(),
        throwsA(isA<NetworkException>()),
      );
      expect(timeline(500).delete('x'), throwsA(isA<NetworkException>()));
      final down = HttpTimelineService(
        baseUrl: _base,
        token: 'tok',
        client: MockClient((_) async => throw const SocketException('down')),
      );
      expect(down.calls(), throwsA(isA<NetworkException>()));
    });
  });

  group('HttpCopilotPauseService', () {
    test('reads inScam with the bearer header', () async {
      final active = await pause(
        200,
        _fixture('pause/response-in-scam.json'),
      ).isActive();
      expect(active, isTrue);
      expect(sent.single.method, 'GET');
      expect(sent.single.url.path, '/copilot/pause');
      expect(sent.single.headers['Authorization'], 'Bearer tok');
    });

    test('clear posts with no body', () async {
      await pause(200, _fixture('pause/response-cleared.json')).clear();
      expect(sent.single.method, 'POST');
      expect(sent.single.url.path, '/copilot/pause/clear');
      expect(sent.single.bodyBytes, isEmpty);
    });

    test('a malformed body throws NetworkException', () {
      expect(pause(200, '{}').isActive(), throwsA(isA<NetworkException>()));
      expect(pause(200, 'x').clear(), throwsA(isA<NetworkException>()));
    });

    test('404 throws NetworkException', () {
      expect(
        pause(404, _notFound).isActive(),
        throwsA(isA<NetworkException>()),
      );
      expect(pause(404, _notFound).clear(), throwsA(isA<NetworkException>()));
    });
  });
}
