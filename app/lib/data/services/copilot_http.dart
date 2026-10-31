import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'network_exception.dart';

/// The co-pilot's bearer-guarded server calls (ADRs 0008, 0010). The token
/// and response bodies are never logged.
class CopilotApi {
  CopilotApi(this._baseUrl, this._token, http.Client? client)
    : _http = client ?? http.Client();

  final Uri _baseUrl;
  final String _token;
  final http.Client _http;

  /// Network errors and timeouts become [NetworkException].
  Future<http.Response> send(String method, String path) async {
    try {
      final req = http.Request(method, _baseUrl.resolve(path))
        ..headers['Authorization'] = 'Bearer $_token';
      return await http.Response.fromStream(
        await _http.send(req).timeout(const Duration(seconds: 10)),
      );
    } on Object {
      throw const NetworkException();
    }
  }

  /// Wrong token, unknown call and unknown path all answer the same bare 404.
  NetworkException refused(http.Response res) {
    if (res.statusCode == 404) {
      debugPrint('Jaga co-pilot request got 404: is JAGA_COPILOT_TOKEN right?');
    }
    return const NetworkException();
  }
}
