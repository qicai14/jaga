import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/core/haptics/fake_buzzer.dart';
import 'package:jaga/core/haptics/vibration_buzzer.dart';

void main() {
  test('FakeBuzzer records calls and state', () async {
    final b = FakeBuzzer();
    await b.startWarningPattern();
    expect(b.buzzing, isTrue);
    await b.stop();
    await b.playOnce();
    expect(b.buzzing, isFalse);
    expect(b.calls, ['start', 'stop', 'once']);
    expect(b.startCount, 1);
  });

  test(
    'VibrationBuzzer: stop during the hasVibrator await prevents vibrating',
    () async {
      final gate = Completer<bool>();
      var vibrated = 0;
      final b = VibrationBuzzer(
        hasVibrator: () => gate.future,
        vibrate: (_, _, _) async => vibrated++,
        cancel: () async {},
      );
      final started = b.startWarningPattern();
      await b.stop();
      gate.complete(true);
      await started;
      expect(vibrated, 0);
    },
  );
}
