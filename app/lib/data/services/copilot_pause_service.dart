import 'dart:convert';

import 'package:http/http.dart' as http;

import 'copilot_http.dart';
import 'network_exception.dart';

/// What the family co-pilot may do with Jaga Pause for the protected user
/// (ADR 0010). Failures throw [NetworkException].
abstract class CopilotPauseService {
  Future<bool> isActive();

  /// Clears Jaga Pause early. Only a family co-pilot can (GLOSSARY).
  Future<void> clear();
}

class HttpCopilotPauseService implements CopilotPauseService {
  HttpCopilotPauseService({
    required Uri baseUrl,
    required String token,
    http.Client? client,
  }) : _api = CopilotApi(baseUrl, token, client);

  final CopilotApi _api;

  @override
  Future<bool> isActive() => _inScam('GET', '/copilot/pause');

  @override
  Future<void> clear() async {
    await _inScam('POST', '/copilot/pause/clear');
  }

  Future<bool> _inScam(String method, String path) async {
    final res = await _api.send(method, path);
    if (res.statusCode != 200) throw _api.refused(res);
    return (jsonDecode(res.body) as Map<String, dynamic>)['inScam'] as bool;
  }
}

/// For tests and the debug gallery.
class FakeCopilotPauseService implements CopilotPauseService {
  FakeCopilotPauseService({this.active = false});

  bool active;

  /// Every call throws [NetworkException], to test failures.
  bool offline = false;

  /// [clear] waits for this first, to show the busy state.
  Future<void>? hold;

  @override
  Future<bool> isActive() async {
    if (offline) throw const NetworkException();
    return active;
  }

  @override
  Future<void> clear() async {
    await hold;
    if (offline) throw const NetworkException();
    active = false;
  }
}
