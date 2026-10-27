import 'network_exception.dart';

/// What the family co-pilot may do with Jaga Pause for the protected user.
/// No contract yet (requested from contracts #1; #15 serves it), so only
/// [FakeCopilotPauseService] implements this. Failures throw [NetworkException].
abstract class CopilotPauseService {
  Future<bool> isActive();

  /// Clears Jaga Pause early. Only a family co-pilot can (GLOSSARY).
  Future<void> clear();
}

/// For tests and the debug gallery.
class FakeCopilotPauseService implements CopilotPauseService {
  FakeCopilotPauseService({this.active = false});

  bool active;

  /// Every call throws [NetworkException], to test failures.
  bool offline = false;

  /// [clear] waits for this first, to show the busy state.
  Future<void>? hold;

  @override
  Future<bool> isActive() async {
    if (offline) throw const NetworkException();
    return active;
  }

  @override
  Future<void> clear() async {
    await hold;
    if (offline) throw const NetworkException();
    active = false;
  }
}
