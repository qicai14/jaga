import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/features/family/views/widgets/home_header.dart';

import '../../support/harness.dart';

Future<void> _load(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    final bytes = File('assets/fonts/$f').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

/// Word splits need the real fonts: the default test font, Ahem, is far wider.
void main() {
  setUpAll(() async {
    await _load('NotoSans', [
      'NotoSans-Regular.ttf',
      'NotoSans-SemiBold.ttf',
      'NotoSans-ExtraBold.ttf',
    ]);
    await _load('NotoSansSC', [
      'NotoSansSC-Regular.otf',
      'NotoSansSC-Bold.otf',
    ]);
  });

  for (final locale in ['en', 'ms', 'zh']) {
    for (final scale in textScales) {
      testWidgets('the header splits no word ($locale x$scale)', (
        tester,
      ) async {
        await pumpJaga(
          tester,
          const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(24),
              child: HomeHeader(name: 'Puan Siti Aminah binti Abdullah'),
            ),
          ),
          scale: scale,
          locale: Locale(locale),
        );
        for (final paragraph in tester.renderObjectList<RenderParagraph>(
          find.descendant(
            of: find.byType(HomeHeader),
            matching: find.byType(RichText),
          ),
        )) {
          // A wrapped paragraph is as wide as its constraint, so a word wider
          // than that was split. (Chinese has no spaces: it wraps by character.)
          final words = RegExp(r'[^\s一-鿿]+');
          for (final w in words.allMatches(paragraph.text.toPlainText())) {
            final word = w.group(0)!;
            final painter = TextPainter(
              text: TextSpan(text: word, style: paragraph.text.style),
              textDirection: TextDirection.ltr,
              textScaler: paragraph.textScaler,
            )..layout();
            expect(
              painter.width,
              lessThanOrEqualTo(paragraph.size.width + 0.5),
              reason: '"$word" is split at $locale x$scale',
            );
          }
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
