import '../models/alerted_call.dart';
import 'network_exception.dart';

/// The stage timelines the server keeps for alerted calls. No contract yet
/// (requested from contracts #1; #16 serves it), so only [FakeTimelineService]
/// implements this. Failures throw [NetworkException].
abstract class TimelineService {
  /// Calls the family was alerted about, newest first. Genuine calls are never listed.
  Future<List<AlertedCall>> calls();

  Future<List<TimelineEvent>> events(String callId);

  /// Deletes a call's timeline. It can't be brought back.
  Future<void> delete(String callId);
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
    deleted.add(callId);
    _calls.removeWhere((c) => c.callId == callId);
    _events.remove(callId);
  }
}
