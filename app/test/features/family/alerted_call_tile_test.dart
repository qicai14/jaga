import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/data/models/alerted_call.dart';
import 'package:jaga/data/models/stage.dart';
import 'package:jaga/features/family/views/widgets/alerted_call_tile.dart';

import '../../support/harness.dart';

/// Word splits need the real fonts: the default test font, Ahem, is far wider.
void main() {
  setUpAll(loadNotoFonts);

  const labels = {'en': 'Live now', 'ms': 'Sedang berlangsung', 'zh': '正在通话'};
  for (final locale in labels.keys) {
    for (final scale in textScales) {
      testWidgets('the Live now badge splits no word ($locale x$scale)', (
        tester,
      ) async {
        await pumpJaga(
          tester,
          Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AlertedCallTile(
                call: AlertedCall(
                  callId: 'c',
                  at: DateTime.utc(2026, 10, 27, 10),
                  stage: Stage.money,
                  claimedAgency: 'Suruhanjaya Pencegahan Rasuah Malaysia',
                  live: true,
                ),
                onTap: () {},
              ),
            ),
          ),
          scale: scale,
          locale: Locale(locale),
        );
        final badge = tester.renderObject<RenderParagraph>(
          find.text(labels[locale]!),
        );
        // A wrapped paragraph is as wide as its constraint, so a word wider
        // than that was split.
        for (final word in labels[locale]!.split(' ')) {
          final painter = TextPainter(
            text: TextSpan(text: word, style: badge.text.style),
            textDirection: TextDirection.ltr,
            textScaler: badge.textScaler,
          )..layout();
          expect(
            painter.width,
            lessThanOrEqualTo(badge.size.width + 0.5),
            reason: '"$word" is split at $locale x$scale',
          );
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
