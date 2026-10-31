import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/stage_update.dart';

/// Live stage updates for the call. The real WebSocket comes with #19.
abstract class StageStreamService {
  Stream<StageUpdate> get updates;

  /// False while the stream is down (the app shows the reconnecting dot).
  ValueListenable<bool> get connected;
}

/// Scripted updates for tests and the debug gallery.
class FakeStageStreamService implements StageStreamService {
  final _controller = StreamController<StageUpdate>.broadcast(sync: true);
  final _connected = ValueNotifier<bool>(true);

  @override
  Stream<StageUpdate> get updates => _controller.stream;

  @override
  ValueListenable<bool> get connected => _connected;

  void emit(StageUpdate update) => _controller.add(update);

  void setConnected(bool value) => _connected.value = value;

  void dispose() {
    _controller.close();
    _connected.dispose();
  }
}
