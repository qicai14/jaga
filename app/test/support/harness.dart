import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/core/l10n/gen/app_localizations.dart';
import 'package:jaga/core/theme/jaga_theme.dart';

/// Every screen test runs at this size, and again at text scale 2.0.
const phoneSize = Size(393, 852);
const textScales = [1.0, 2.0];

/// Pumps [child] in the Jaga theme at 393x852 with the given text scale.
Future<void> pumpJaga(
  WidgetTester tester,
  Widget child, {
  double scale = 1.0,
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = phoneSize;
  tester.view.devicePixelRatio = 1.0;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
  await tester.pumpWidget(
    MaterialApp(
      theme: buildJagaTheme(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
  await tester.pumpAndSettle();
}

/// Runs [body] once per text scale, each as its own test, failing on any
/// framework exception (overflow included).
void forEachScale(
  String name,
  Future<void> Function(WidgetTester tester, double scale) body,
) {
  for (final scale in textScales) {
    testWidgets('$name (393x852, text x$scale)', (tester) async {
      await body(tester, scale);
      expect(tester.takeException(), isNull);
    });
  }
}

/// Loads the real Noto Sans fonts (Latin and Chinese). The default test font,
/// Ahem, is far wider, so tests that count lines or split words need these.
Future<void> loadNotoFonts() async {
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      final bytes = File('assets/fonts/$f').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }

  await load('NotoSans', [
    'NotoSans-Regular.ttf',
    'NotoSans-SemiBold.ttf',
    'NotoSans-ExtraBold.ttf',
  ]);
  await load('NotoSansSC', ['NotoSansSC-Regular.otf', 'NotoSansSC-Bold.otf']);
}

/// Fails if any word of any text under [within] (default: the whole tree) is
/// wider than its line, i.e. split mid-word. Needs [loadNotoFonts]. CJK wraps
/// by character, so only runs of other characters count as words.
void expectNoSplitWords(WidgetTester tester, {Finder? within}) {
  final root = within ?? find.byType(MaterialApp);
  final paragraphs = tester.renderObjectList<RenderParagraph>(
    find.descendant(of: root, matching: find.byType(RichText)),
  );
  for (final p in paragraphs) {
    final style = p.text.style;
    if (style == null) continue;
    final plain = p.text.toPlainText();
    for (final w in RegExp(r'[^\s一-鿿]+').allMatches(plain)) {
      final painter = TextPainter(
        text: TextSpan(text: w.group(0), style: style),
        textDirection: TextDirection.ltr,
        textScaler: p.textScaler,
      )..layout();
      expect(
        painter.width,
        lessThanOrEqualTo(p.size.width + 0.5),
        reason: '"${w.group(0)}" is split in "$plain"',
      );
    }
  }
}
