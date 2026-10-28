import 'dart:convert';

import 'package:http/http.dart' as http;

/// Jaga Pause answer (contracts/pause.schema.json).
class PauseAnswer {
  const PauseAnswer({
    required this.inScam,
    required this.recommendedHoldMinutes,
    this.claimedAgency,
  });

  factory PauseAnswer.fromJson(Map<String, dynamic> json) => PauseAnswer(
    inScam: json['inScam'] as bool,
    recommendedHoldMinutes: json['recommendedHoldMinutes'] as int,
    claimedAgency: json['claimedAgency'] as String?,
  );

  final bool inScam;
  final int recommendedHoldMinutes;
  final String? claimedAgency;
}

/// Any reason we could not get an answer (unknown token, network, bad JSON).
class PauseFailure implements Exception {
  const PauseFailure(this.message);
  final String message;
}

abstract interface class PauseClient {
  Future<PauseAnswer> ask(String pauseToken);
}

class HttpPauseClient implements PauseClient {
  HttpPauseClient(this.baseUrl, this._http);
  final Uri baseUrl;
  final http.Client _http;

  @override
  Future<PauseAnswer> ask(String pauseToken) async {
    try {
      final res = await _http
          .post(
            baseUrl.resolve('/pause'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'pauseToken': pauseToken}),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 404) {
        throw const PauseFailure('Unknown pause token');
      }
      if (res.statusCode != 200) {
        throw PauseFailure('Jaga Pause returned ${res.statusCode}');
      }
      return PauseAnswer.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    } on PauseFailure {
      rethrow;
    } catch (_) {
      throw const PauseFailure('Could not reach Jaga Pause');
    }
  }
}
