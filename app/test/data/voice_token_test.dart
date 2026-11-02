import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jaga/data/services/network_exception.dart';
import 'package:jaga/data/services/voice_token_service.dart';

const _body =
    '{"token":"aGVhZGVy.cGF5bG9hZA.c2lnbmF0dXJl","expiresAt":"2026-10-31T04:00:00+00:00"}';

HttpVoiceTokenService _service(MockClient client) => HttpVoiceTokenService(
  baseUrl: Uri.parse('https://jaga.example'),
  appToken: 'secret',
  client: client,
);

void main() {
  test('POSTs /voice-token with the app secret as a bearer token', () async {
    late http.Request seen;
    final token = await _service(
      MockClient((r) async {
        seen = r;
        return http.Response(_body, 200);
      }),
    ).fetch();
    expect(seen.method, 'POST');
    expect(seen.url.toString(), 'https://jaga.example/voice-token');
    expect(seen.headers['Authorization'], 'Bearer secret');
    expect(token.token, 'aGVhZGVy.cGF5bG9hZA.c2lnbmF0dXJl');
    expect(token.expiresAt, DateTime.utc(2026, 10, 31, 4));
  });

  test('a 404, a 503 or a broken body is a NetworkException', () async {
    for (final res in [
      http.Response('', 404),
      http.Response('{"detail":"X is not set"}', 503),
      http.Response('not json', 200),
    ]) {
      await expectLater(
        _service(MockClient((_) async => res)).fetch(),
        throwsA(isA<NetworkException>()),
      );
    }
  });

  test('the fake returns a placeholder that expires in an hour', () async {
    final t = await FakeVoiceTokenService(now: () => DateTime.utc(2026))
        .fetch();
    expect(t.token.split('.'), hasLength(3));
    expect(t.expiresAt, DateTime.utc(2026, 1, 1, 1));
  });
}
