import 'buzzer.dart';

/// Records calls; for tests and the debug gallery.
class FakeBuzzer implements Buzzer {
  final calls = <String>[];
  bool buzzing = false;

  int get startCount => calls.where((c) => c == 'start').length;

  @override
  Future<void> startWarningPattern() async {
    calls.add('start');
    buzzing = true;
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
    buzzing = false;
  }

  @override
  Future<void> playOnce() async => calls.add('once');
}
