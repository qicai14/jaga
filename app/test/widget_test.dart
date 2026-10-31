import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/main.dart';

void main() {
  testWidgets('app starts with the Jaga theme and l10n', (tester) async {
    await tester.pumpWidget(const JagaApp());
    await tester.pumpAndSettle();
    expect(find.text('Jaga'), findsOneWidget);
    expect(Theme.of(tester.element(find.text('Jaga'))).useMaterial3, isTrue);
  });
}
