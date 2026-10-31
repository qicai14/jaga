import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/alerted_call.dart';
import 'copilot_http.dart';
import 'network_exception.dart';

/// The stage timelines the server keeps for alerted calls (ADR 0008).
/// Failures throw [NetworkException].
abstract class TimelineService {
  /// Calls the family was alerted about, newest first. Genuine calls are never listed.
  Future<List<AlertedCall>> calls();

  Future<List<TimelineEvent>> events(String callId);

  /// Deletes a call's timeline. It can't be brought back.
  Future<void> delete(String callId);
}

class HttpTimelineService implements TimelineService {
  HttpTimelineService({
    required Uri baseUrl,
    required String token,
    http.Client? client,
  }) : _api = CopilotApi(baseUrl, token, client);

  final CopilotApi _api;

  @override
  Future<List<AlertedCall>> calls() async {
    final res = await _api.send('GET', '/timelines');
    if (res.statusCode != 200) throw _api.refused(res);
    return [
      for (final j in jsonDecode(res.body) as List)
        AlertedCall.fromJson(j as Map<String, dynamic>),
    ];
  }

  /// A timeline the server no longer has (deleted, or past 30 days) has no events.
  @override
  Future<List<TimelineEvent>> events(String callId) async {
    final res = await _api.send('GET', '/timelines/$callId');
    if (res.statusCode == 404) return const [];
    if (res.statusCode != 200) throw _api.refused(res);
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return [
      for (final e in json['events'] as List)
        TimelineEvent.fromJson(e as Map<String, dynamic>),
    ];
  }

  /// Already gone counts as deleted.
  @override
  Future<void> delete(String callId) async {
    final res = await _api.send('DELETE', '/timelines/$callId');
    if (res.statusCode != 204 && res.statusCode != 404) throw _api.refused(res);
  }
}

/// For tests and the debug gallery.
class FakeTimelineService implements TimelineService {
  FakeTimelineService({
    List<AlertedCall> calls = const [],
    Map<String, List<TimelineEvent>> events = const {},
  }) : _calls = [...calls],
       _events = {...events};

  final List<AlertedCall> _calls;
  final Map<String, List<TimelineEvent>> _events;

  /// Every call throws [NetworkException], to test failures.
  bool offline = false;

  /// [delete] waits for this first, to show the busy state.
  Future<void>? hold;

  /// Ids passed to [delete], in order.
  final deleted = <String>[];

  void _reach() {
    if (offline) throw const NetworkException();
  }

  @override
  Future<List<AlertedCall>> calls() async {
    _reach();
    return [..._calls];
  }

  @override
  Future<List<TimelineEvent>> events(String callId) async {
    _reach();
    return [...?_events[callId]];
  }

  @override
  Future<void> delete(String callId) async {
    _reach();
    await hold;
    deleted.add(callId);
    _calls.removeWhere((c) => c.callId == callId);
    _events.remove(callId);
  }
}
