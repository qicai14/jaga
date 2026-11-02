import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/core/widgets/big_button.dart';
import 'package:jaga/data/models/stage_update.dart';
import 'package:jaga/debug/fixtures/stage_update_fixtures.dart';

import 'warning_overlay_test.dart' show emit, pump;

/// Measured with the real Noto Sans (the default test font, Ahem, is about 1.6x
/// wider and would fail the budget for the wrong reason).
void main() {
  setUpAll(() async {
    final loader = FontLoader('NotoSans');
    for (final f in ['Regular', 'SemiBold', 'ExtraBold']) {
      final bytes = File('assets/fonts/NotoSans-$f.ttf').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  });

  final cases = {
    'high': (
      stageHigh,
      'Polis tidak akan minta wang atau kata laluan melalui telefon. Hubungi PDRM sendiri di 03-2266 2222.',
    ),
    'credentials': (
      stageHighCredentials,
      'Bank tidak akan minta kod TAC anda. Letak telefon dan hubungi bank anda sendiri di 03-2174 1717.',
    ),
  };
  for (final MapEntry(key: name, value: (fixture, counter))
      in cases.entries) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        '$name at 393x852, text x$scale: command and counter-move sit above Hang up',
        (tester) async {
          final rig = await pump(tester, scale);
          await emit(tester, rig, fixture);
          final hang = tester.getRect(find.byType(BigButton)).top;
          final command = StageUpdate.parse(fixture).command!;
          for (final t in [command, counter]) {
            final r = tester.getRect(find.text(t));
            expect(r.top, greaterThanOrEqualTo(0), reason: t);
            expect(r.bottom, lessThanOrEqualTo(hang), reason: t);
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
