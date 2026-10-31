import 'package:http/http.dart' as http;

import '../models/voice_token.dart';
import 'network_exception.dart';

/// Fetches the Voice access token that lets Twilio ring this phone (ADR 0009).
abstract class VoiceTokenService {
  Future<VoiceToken> fetch();
}

class HttpVoiceTokenService implements VoiceTokenService {
  /// [appToken] is `JAGA_APP_TOKEN`, a build-time secret (ADR 0009).
  HttpVoiceTokenService({
    required this.baseUrl,
    required this._appToken,
    http.Client? client,
  }) : _http = client ?? http.Client();

  final Uri baseUrl;
  final String _appToken;
  final http.Client _http;

  @override
  Future<VoiceToken> fetch() async {
    try {
      final res = await _http
          .post(
            baseUrl.resolve('/voice-token'),
            headers: {'Authorization': 'Bearer $_appToken'},
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) throw const NetworkException();
      return VoiceToken.parse(res.body);
    } on NetworkException {
      rethrow;
    } on Object {
      // The body is a credential: nothing from it goes into the error.
      throw const NetworkException();
    }
  }
}

/// No server: a placeholder Twilio will refuse, so the fake path never registers by accident.
class FakeVoiceTokenService implements VoiceTokenService {
  FakeVoiceTokenService({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  int fetches = 0;

  @override
  Future<VoiceToken> fetch() async {
    fetches++;
    return VoiceToken(
      token: 'ZmFrZQ.ZmFrZQ.ZmFrZQ',
      expiresAt: _now().add(const Duration(hours: 1)),
    );
  }
}
