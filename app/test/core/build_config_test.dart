import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/core/config/build_config.dart';

void main() {
  BuildRole role(bool app, bool copilot) =>
      BuildRole.from(appToken: app, copilotToken: copilot);

  test('no token is a dev build with both roles', () {
    final r = role(false, false);
    expect(r, BuildRole.dev);
    expect([r.offersProtected, r.offersCopilot], [true, true]);
  });

  test('the app token makes a protected-user build', () {
    final r = role(true, false);
    expect(r, BuildRole.protectedUser);
    expect([r.offersProtected, r.offersCopilot], [true, false]);
  });

  test('the co-pilot token makes a co-pilot build', () {
    final r = role(false, true);
    expect(r, BuildRole.copilot);
    expect([r.offersProtected, r.offersCopilot], [false, true]);
  });

  test('both tokens are refused', () {
    expect(() => role(true, true), throwsStateError);
  });
}
