import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/stage_update.dart';

/// Live stage updates for the call: [WebSocketStageStreamService] on the real server.
abstract class StageStreamService {
  Stream<StageUpdate> get updates;

  /// False while the stream is down (the app shows the reconnecting dot).
  ValueListenable<bool> get connected;

  /// Starts (or restarts) the stream for the Twilio CallSid of the inbound call.
  void connect(String callId);

  /// Stops the stream and any retry.
  void close();
}

/// `/calls/{callId}/stages` on the server, one JSON `stage-update` per message.
/// The server replays every update on each connect, so after a drop the first
/// messages already delivered are skipped. Drops retry on [backoff]; a rejected
/// handshake (unknown call) or a normal close (call ended) stops.
class WebSocketStageStreamService implements StageStreamService {
  WebSocketStageStreamService(
    this._serverUrl, {
    this.backoff = const [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 4),
      Duration(seconds: 8),
    ],
  });

  static const maxRefusals = 5;

  final Uri _serverUrl;
  final List<Duration> backoff;
  final _controller = StreamController<StageUpdate>.broadcast();
  final _connected = ValueNotifier<bool>(true);
  WebSocket? _socket;
  int _generation = 0;
  Timer? _retry;
  Completer<void>? _retryDone;

  @override
  Stream<StageUpdate> get updates => _controller.stream;

  @override
  ValueListenable<bool> get connected => _connected;

  @override
  void connect(String callId) {
    close();
    unawaited(_run(callId, _generation));
  }

  @override
  void close() {
    _generation++;
    _retry?.cancel();
    // Wakes _run, which sees the new generation and ends.
    if (_retryDone case final done? when !done.isCompleted) done.complete();
    _retry = null;
    _retryDone = null;
    _socket?.close();
    _socket = null;
    _connected.value = true;
  }

  Uri _url(String callId) => _serverUrl.replace(
    scheme: _serverUrl.scheme == 'https' ? 'wss' : 'ws',
    path: '/calls/${Uri.encodeComponent(callId)}/stages',
  );

  Future<void> _run(String callId, int generation) async {
    var delivered = 0; // messages already shown, replayed again after a drop
    var failures = 0;
    var refusals = 0;
    while (generation == _generation) {
      WebSocket? socket;
      try {
        socket = await WebSocket.connect(_url(callId).toString())
            .timeout(const Duration(seconds: 10));
        if (generation != _generation) {
          unawaited(socket.close());
          return;
        }
        socket.pingInterval = const Duration(seconds: 20);
        _socket = socket;
        _connected.value = true;
        failures = 0;
        refusals = 0;
        var index = 0;
        await for (final message in socket) {
          if (index++ < delivered) continue;
          delivered = index;
          _deliver(message);
        }
      } on WebSocketException catch (e) {
        // The server answers 403 for an unknown call, 502/503 mid-deploy. Some
        // SDKs leave the status out of the message, so a refusal also gives up
        // after [maxRefusals] in a row.
        if (socket == null &&
            (e.message.contains('status code: 403') ||
                ++refusals >= maxRefusals)) {
          debugPrint('Stage stream refused: unknown call');
          return;
        }
      } on Object catch (e) {
        debugPrint('Stage stream dropped: ${e.runtimeType}');
      }
      final code = socket?.closeCode;
      if (generation != _generation ||
          code == WebSocketStatus.normalClosure ||
          code == WebSocketStatus.policyViolation) {
        return;
      }
      _connected.value = false;
      final wait =
          backoff[failures < backoff.length ? failures : backoff.length - 1];
      failures++;
      final done = _retryDone = Completer<void>();
      _retry = Timer(wait, done.complete);
      await done.future;
    }
  }

  void _deliver(Object? message) {
    try {
      _controller.add(StageUpdate.parse(message as String));
    } on Object catch (e) {
      // Never log the content: it can carry the caller's words.
      debugPrint('Stage update ignored: ${e.runtimeType}');
    }
  }
}

/// Scripted updates for tests and the debug gallery.
class FakeStageStreamService implements StageStreamService {
  final _controller = StreamController<StageUpdate>.broadcast(sync: true);
  final _connected = ValueNotifier<bool>(true);

  @override
  Stream<StageUpdate> get updates => _controller.stream;

  @override
  ValueListenable<bool> get connected => _connected;

  final connectedCalls = <String>[];
  int closeCount = 0;

  @override
  void connect(String callId) => connectedCalls.add(callId);

  @override
  void close() => closeCount++;

  void emit(StageUpdate update) => _controller.add(update);

  void setConnected(bool value) => _connected.value = value;

  void dispose() {
    _controller.close();
    _connected.dispose();
  }
}
