import 'dart:async';

import 'package:vibration/vibration.dart';

import 'buzzer.dart';

/// Real buzzer on the `vibration` plugin. Android only (ADR 0001).
class VibrationBuzzer implements Buzzer {
  // off, on pairs: three short, one long; then a 1 s gap (the last off entry).
  static const _pattern = [0, 120, 80, 120, 80, 120, 80, 700, 1000];
  static const _intensities = [0, 255, 0, 255, 0, 255, 0, 255, 0];
  static const maxDuration = Duration(seconds: 60);

  VibrationBuzzer({
    Future<bool> Function()? hasVibrator,
    Future<void> Function(List<int> pattern, List<int> intensities, int repeat)?
    vibrate,
    Future<void> Function()? cancel,
  }) : _hasVibrator =
           hasVibrator ?? (() async => await Vibration.hasVibrator()),
       _vibrate =
           vibrate ??
           ((p, i, r) =>
               Vibration.vibrate(pattern: p, intensities: i, repeat: r)),
       _cancel = cancel ?? Vibration.cancel;

  final Future<bool> Function() _hasVibrator;
  final Future<void> Function(List<int>, List<int>, int) _vibrate;
  final Future<void> Function() _cancel;

  Timer? _cap;
  // Bumped by start and stop, so a start that awaited across a stop gives up.
  int _generation = 0;

  @override
  Future<void> startWarningPattern() async {
    _cap?.cancel();
    final gen = ++_generation;
    if (!await _hasVibrator() || gen != _generation) return;
    await _vibrate(_pattern, _intensities, 0);
    if (gen != _generation) {
      await _cancel();
      return;
    }
    _cap = Timer(maxDuration, stop);
  }

  @override
  Future<void> playOnce() async {
    if (!await _hasVibrator()) return;
    await _vibrate(_pattern.sublist(0, 8), _intensities.sublist(0, 8), -1);
  }

  @override
  Future<void> stop() async {
    _generation++;
    _cap?.cancel();
    _cap = null;
    await _cancel();
  }
}
