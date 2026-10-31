import 'dart:async';

import 'package:proximity_sensor/proximity_sensor.dart';

/// Tells the app she has looked at the phone (it left her ear), so the Warning
/// buzz can stop.
abstract class AttentionService {
  /// Fires once each time the phone has been "far" for [holdFar].
  Stream<void> get looked;
}

class FakeAttentionService implements AttentionService {
  final _controller = StreamController<void>.broadcast(sync: true);

  @override
  Stream<void> get looked => _controller.stream;

  void lookNow() => _controller.add(null);
}

/// Real one on the proximity sensor (events: 0 far, above 0 near). Android only.
class ProximityAttentionService implements AttentionService {
  static const holdFar = Duration(seconds: 1);

  @override
  Stream<void> get looked {
    Timer? timer;
    late StreamController<void> out;
    StreamSubscription<int>? sub;
    out = StreamController<void>(
      onListen: () {
        sub = ProximitySensor.events.listen((value) {
          timer?.cancel();
          if (value > 0) return;
          timer = Timer(holdFar, () => out.add(null));
        });
      },
      onCancel: () {
        timer?.cancel();
        return sub?.cancel();
      },
    );
    return out.stream;
  }
}
