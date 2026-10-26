import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/core/haptics/fake_buzzer.dart';

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
}
