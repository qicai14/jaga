import 'dart:async';

import 'package:vibration/vibration.dart';

import 'buzzer.dart';

/// Real buzzer on the `vibration` plugin. Android only (ADR 0001).
class VibrationBuzzer implements Buzzer {
  // off, on pairs: three short, one long; then a 1 s gap (the last off entry).
  static const _pattern = [0, 120, 80, 120, 80, 120, 80, 700, 1000];
  static const _intensities = [0, 255, 0, 255, 0, 255, 0, 255, 0];
  static const maxDuration = Duration(seconds: 60);

  Timer? _cap;

  @override
  Future<void> startWarningPattern() async {
    _cap?.cancel();
    if (!await Vibration.hasVibrator()) return;
    await Vibration.vibrate(
        pattern: _pattern, intensities: _intensities, repeat: 0);
    _cap = Timer(maxDuration, stop);
  }

  @override
  Future<void> playOnce() async {
    if (!await Vibration.hasVibrator()) return;
    await Vibration.vibrate(pattern: _pattern.sublist(0, 8), intensities: _intensities.sublist(0, 8));
  }

  @override
  Future<void> stop() async {
    _cap?.cancel();
    _cap = null;
    await Vibration.cancel();
  }
}
