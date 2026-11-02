import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/core/l10n/date_text.dart';

import '../support/harness.dart';

void main() {
  final at = DateTime(2026, 10, 27, 14, 5);
  final tomorrow = DateTime(2026, 10, 28, 9);

  String? out;
  Widget probe(DateTime now) => Builder(
    builder: (context) {
      // Newer ICU puts a narrow no-break space before AM/PM.
      out = at.formatWhen(context, now: now).replaceAll(' ', ' ');
      return const SizedBox();
    },
  );

  for (final (locale, today, other) in [
    ('en', '2:05 PM', 'Oct 27, 2026 2:05 PM'),
    ('ms', '2:05 PTG', '27 Okt 2026 2:05 PTG'),
    ('zh', '14:05', '2026年10月27日 14:05'),
  ]) {
    testWidgets('formatWhen in $locale: time today, date after', (
      tester,
    ) async {
      await pumpJaga(
        tester,
        probe(DateTime(2026, 10, 27, 20)),
        locale: Locale(locale),
      );
      expect(out, today);
      await pumpJaga(tester, probe(tomorrow), locale: Locale(locale));
      expect(out, other);
    });
  }
}
