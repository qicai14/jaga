import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/core/theme/text_scale.dart';
import 'package:jaga/core/widgets/role_badge.dart';
import 'package:jaga/core/widgets/screen_frame.dart';

import '../support/harness.dart';

const _labels = {
  'en': ('Family', 'Protected phone'),
  'ms': ('Keluarga', 'Telefon dilindungi'),
  'zh': ('家人', '受保护的手机'),
};

/// Word splits need the real fonts: the default test font, Ahem, is far wider.
void main() {
  setUpAll(loadNotoFonts);

  Future<void> expectNoSplit(
    WidgetTester tester,
    String label,
    String what,
  ) async {
    final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
    // A wrapped paragraph is as wide as its constraint, so a word wider than
    // that was split. (Chinese wraps by character.)
    for (final w in RegExp(r'[^\s一-鿿]+').allMatches(label)) {
      final painter = TextPainter(
        text: TextSpan(text: w.group(0), style: paragraph.text.style),
        textDirection: TextDirection.ltr,
        textScaler: paragraph.textScaler,
      )..layout();
      expect(
        painter.width,
        lessThanOrEqualTo(paragraph.size.width + 0.5),
        reason: '"${w.group(0)}" is split ($what)',
      );
    }
  }

  for (final locale in ['en', 'ms', 'zh']) {
    for (final scale in textScales) {
      testWidgets(
        'the family badge splits no word at its 1.5 cap ($locale x$scale)',
        (tester) async {
          final label = _labels[locale]!.$1;
          await pumpJaga(
            tester,
            MediaQuery.withClampedTextScaling(
              maxScaleFactor: copilotMaxTextScale, // as in the app
              child: const ScreenFrame(
                role: RoleBadge.family(),
                title: 'Title',
                body: SizedBox(),
              ),
            ),
            scale: scale,
            locale: Locale(locale),
          );
          await expectNoSplit(tester, label, 'family $locale x$scale');
          final badge = tester.getRect(
            find
                .ancestor(
                  of: find.text(label),
                  matching: find.byType(Container),
                )
                .first,
          );
          // End-aligned (24dp screen padding) and above the title.
          expect(badge.right, closeTo(393 - 24, 0.5));
          expect(
            badge.bottom,
            lessThanOrEqualTo(tester.getTopLeft(find.text('Title')).dy),
          );
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'the protected badge splits no word at full scale ($locale x$scale)',
        (tester) async {
          final label = _labels[locale]!.$2;
          await pumpJaga(
            tester,
            const ScreenFrame(
              role: RoleBadge.protected(),
              title: 'Title',
              body: SizedBox(),
            ),
            scale: scale,
            locale: Locale(locale),
          );
          await expectNoSplit(tester, label, 'protected $locale x$scale');
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
