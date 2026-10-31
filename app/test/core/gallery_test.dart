import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/debug/gallery_app.dart';
import 'package:jaga/debug/gallery_registry.dart';

import '../support/harness.dart';

void main() {
  final entries = galleryEntries();

  // Every registered state must render in every language at 393x852 and text x2.
  for (final locale in const ['ms', 'en', 'zh', 'ta']) {
    for (final scale in textScales) {
      testWidgets('gallery entries render: $locale, x$scale', (tester) async {
        for (final e in entries) {
          await pumpJaga(tester, Builder(builder: e.build),
              scale: scale, locale: Locale(locale));
          expect(tester.takeException(), isNull,
              reason: '${e.feature}: ${e.state}');
        }
      });
    }
  }

  testWidgets('gallery home lists entries and opens one', (tester) async {
    await pumpJaga(tester, GalleryHome(entries: entries));
    await tester.tap(find.text('BigButton guarded'));
    await tester.pumpAndSettle();
    expect(find.text('Jaga sedang melindungi anda'), findsOneWidget);
  });
}
