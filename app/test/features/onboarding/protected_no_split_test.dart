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

  // Every state of her status screen, then the unlocked settings.
  final states = <String, Future<void> Function(WidgetTester, Locale)>{
    'status with family': (t, l) =>
        pumpHome(t, scale: 2.0, locale: l, family: ['Aisyah', 'Daniel']),
    'status with no family': (t, l) => pumpHome(t, scale: 2.0, locale: l),
    'ask your family': (t, l) =>
        pumpHome(t, scale: 2.0, locale: l, device: FakeDeviceSetupService()),
    'settings': (t, l) async {
      await pumpHome(t, scale: 2.0, locale: l);
      // The gate's title is English-only in openGate; the badge is any locale.
      await t.longPress(find.byType(RoleBadge));
      await t.pumpAndSettle();
      await unlockWith(t, '1234');
    },
  };
  for (final locale in ['en', 'ms', 'zh']) {
    for (final MapEntry(key: name, value: pump) in states.entries) {
      testWidgets('$name splits no word ($locale x2.0)', (tester) async {
        await pump(tester, Locale(locale));
        expectNoSplitWords(tester);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
