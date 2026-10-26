/// Plays the Warning buzz (warning.md section 6). Button feedback does not go
/// through here: it uses Flutter's `HapticFeedback` directly.
abstract class Buzzer {
  /// Repeats the three-short-one-long pattern until [stop] or 60 s.
  Future<void> startWarningPattern();

  Future<void> stop();

  /// One cycle of the pattern, for onboarding's "Feel the buzz".
  Future<void> playOnce();
}
