import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/main.dart';

void main() {
  testWidgets('app starts', (tester) async {
    await tester.pumpWidget(const JagaApp());
    expect(find.text('Jaga'), findsOneWidget);
  });
}
