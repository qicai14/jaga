/// Which build this is (ADR 0010): the co-pilot token must never ship in the
/// APK on the protected user's phone, so each token marks its own build.
enum BuildRole {
  /// No token: both roles, all Fakes.
  dev,

  /// `JAGA_APP_TOKEN` set: only the protected role.
  protectedUser,

  /// `JAGA_COPILOT_TOKEN` set: only the family co-pilot role.
  copilot;

  /// Both tokens in one build would put the co-pilot token on a protected
  /// phone, so this throws (debug and release) without printing either.
  static BuildRole from({required bool appToken, required bool copilotToken}) {
    if (appToken && copilotToken) {
      throw StateError(
        'JAGA_APP_TOKEN and JAGA_COPILOT_TOKEN are both set. Build the '
        'protected-user app and the co-pilot app separately (ADR 0010).',
      );
    }
    if (appToken) return protectedUser;
    if (copilotToken) return copilot;
    return dev;
  }

  bool get offersProtected => this != copilot;
  bool get offersCopilot => this != protectedUser;
}
