import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jaga/features/demo_bank/pause_client.dart';

String raw(String name) =>
    File('../contracts/fixtures/pause/$name.json').readAsStringSync();
Map<String, dynamic> fixture(String name) =>
    jsonDecode(raw(name)) as Map<String, dynamic>;

void main() {
  group('PauseAnswer.fromJson', () {
    test('in-scam fixture', () {
      final a = PauseAnswer.fromJson(fixture('response-in-scam'));
      expect(a.inScam, isTrue);
      expect(a.recommendedHoldMinutes, 30);
      expect(a.claimedAgency, 'PDRM');
    });

    test('not-in-scam fixture has null agency', () {
      final a = PauseAnswer.fromJson(fixture('response-not-in-scam'));
      expect(a.inScam, isFalse);
      expect(a.claimedAgency, isNull);
    });

    test('claimedAgency may be absent', () {
      final a = PauseAnswer.fromJson({
        'inScam': true,
        'recommendedHoldMinutes': 5,
      });
      expect(a.claimedAgency, isNull);
    });
  });

  group('HttpPauseClient', () {
    final base = Uri.parse('http://server.test');

    test('posts the token body and parses the answer', () async {
      late http.Request seen;
      final client = HttpPauseClient(
        base,
        MockClient((r) async {
          seen = r;
          return http.Response(raw('response-in-scam'), 200);
        }),
      );
      final a = await client.ask('tok');
      expect(seen.method, 'POST');
      expect(seen.url.path, '/pause');
      final body = jsonDecode(seen.body) as Map<String, dynamic>;
      expect(body, {'pauseToken': 'tok'});
      expect(body.keys, fixture('request-valid').keys);
      expect(a.inScam, isTrue);
    });

    test('404 is a PauseFailure', () {
      final client = HttpPauseClient(
        base,
        MockClient((_) async => http.Response('', 404)),
      );
      expect(client.ask('x'), throwsA(isA<PauseFailure>()));
    });

    test('network and parse errors are PauseFailure', () {
      final net = HttpPauseClient(
        base,
        MockClient((_) async => throw http.ClientException('down')),
      );
      final bad = HttpPauseClient(
        base,
        MockClient((_) async => http.Response('not json', 200)),
      );
      expect(net.ask('x'), throwsA(isA<PauseFailure>()));
      expect(bad.ask('x'), throwsA(isA<PauseFailure>()));
    });
  });
}
