@Tags(['screenshots'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/core/l10n/gen/app_localizations.dart';
import 'package:jaga/core/theme/jaga_theme.dart';
import 'package:jaga/debug/gallery_registry.dart';

import '../support/harness.dart';

const _dpr = 2.625;
final _outDir = Directory('build/screenshots');

Future<void> _load(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    final bytes = File(f).readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

String _slug(String s) => s
    .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-|-$'), '');

void main() {
  setUpAll(() async {
    const dir = 'assets/fonts/';
    await _load('NotoSans', [
      '${dir}NotoSans-Regular.ttf',
      '${dir}NotoSans-SemiBold.ttf',
      '${dir}NotoSans-ExtraBold.ttf',
    ]);
    await _load('NotoSansSC', [
      '${dir}NotoSansSC-Regular.otf',
      '${dir}NotoSansSC-Bold.otf',
    ]);
    await _load('NotoSansTamil', [
      '${dir}NotoSansTamil-Regular.ttf',
      '${dir}NotoSansTamil-SemiBold.ttf',
      '${dir}NotoSansTamil-ExtraBold.ttf',
    ]);
    // Icons: the SDK's fonts, found through FLUTTER_ROOT (set by `flutter test`).
    final root = Platform.environment['FLUTTER_ROOT'];
    final icons = root == null
        ? null
        : File(
            '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
          );
    if (icons != null && icons.existsSync()) {
      await _load('MaterialIcons', [icons.path]);
    } else {
      // ignore: avoid_print
      print('MaterialIcons not found: icons will render as boxes.');
    }
    _outDir.createSync(recursive: true);
  });

  final entries = galleryEntries();

  // (locale, scale) combinations per entry state.
  List<(String, double)> variants(String feature, String state) {
    if (feature != 'warning') return [('ms', 1.0), ('en', 1.0)];
    return [
      ('ms', 1.0),
      ('en', 1.0),
      if (state == 'high') ...[('ta', 1.0), ('zh', 1.0)],
      if (state == 'high' || state == 'medium') ...[('ms', 2.0), ('en', 2.0)],
    ];
  }

  for (final e in entries) {
    for (final (locale, scale) in variants(e.feature, e.state)) {
      final name = '${_slug(e.feature)}_${_slug(e.state)}_${locale}_$scale';
      testWidgets('screenshot $name', (tester) async {
        tester.view.physicalSize = Size(
          phoneSize.width * _dpr,
          phoneSize.height * _dpr,
        );
        tester.view.devicePixelRatio = _dpr;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.platformDispatcher.clearTextScaleFactorTestValue();
        });
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: buildJagaTheme(Locale(locale)),
              locale: Locale(locale),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Builder(builder: e.build),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: _dpr);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('${_outDir.path}/$name.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      });
    }
  }
}
