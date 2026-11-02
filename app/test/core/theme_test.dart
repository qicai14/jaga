import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/core/theme/jaga_theme.dart';

void main() {
  test('no text style below 20sp', () {
    final en = buildJagaTheme(const Locale('en'));
    final t = en.textTheme;
    for (final s in [t.bodySmall, t.bodyMedium, t.labelSmall, t.labelMedium, t.titleSmall]) {
      expect(s!.fontSize, greaterThanOrEqualTo(20));
    }
  });

  test('scheme and fonts follow the brief', () {
    final th = buildJagaTheme(const Locale('en'));
    expect(th.extensions.length, 3);
    expect(th.colorScheme.primary, const Color(0xFF0B5D4F));
    expect(th.textTheme.bodyLarge!.fontFamily, 'NotoSans');
    expect(th.textTheme.bodyLarge!.fontFamilyFallback, ['NotoSansSC']);
  });
}
