import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/core/widgets/role_badge.dart';
import 'package:jaga/data/services/device_setup_service.dart';

import '../../support/harness.dart';
import 'protected_home_test.dart' show pumpHome, unlockWith;

/// The protected side keeps the full system text size (2.0), so no word may
/// split on her screens. Real fonts: the default test font is far wider.
void main() {
  setUpAll(loadNotoFonts);

  for (final locale in ['en', 'ms', 'zh']) {
    final l = Locale(locale);

    testWidgets('the status screen splits no word ($locale x2.0)', (
      tester,
    ) async {
      await pumpHome(
        tester,
        scale: 2.0,
        locale: l,
        family: ['Aisyah', 'Daniel'],
      );
      expectNoSplitWords(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the status screen with no family splits no word ($locale)', (
      tester,
    ) async {
      await pumpHome(tester, scale: 2.0, locale: l);
      expectNoSplitWords(tester);
    });

    testWidgets('the ask-your-family state splits no word ($locale x2.0)', (
      tester,
    ) async {
      await pumpHome(
        tester,
        scale: 2.0,
        locale: l,
        device: FakeDeviceSetupService(),
      );
      expectNoSplitWords(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the protected settings split no word ($locale x2.0)', (
      tester,
    ) async {
      await pumpHome(tester, scale: 2.0, locale: l);
      // The gate's title is English-only in openGate; the badge is any locale.
      await tester.longPress(find.byType(RoleBadge));
      await tester.pumpAndSettle();
      await unlockWith(tester, '1234');
      expectNoSplitWords(tester);
      expect(tester.takeException(), isNull);
    });
  }
}
