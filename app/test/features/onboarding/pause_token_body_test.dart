import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/features/onboarding/views/widgets/pause_token_body.dart';

import '../../support/harness.dart';

void main() {
  late String? clip;

  setUp(() {
    clip = null;
  });

  Future<void> mockClipboard(WidgetTester tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clip = (call.arguments as Map)['text'] as String?;
        } else if (call.method == 'Clipboard.getData') {
          return clip == null ? null : {'text': clip};
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
  }

  const token = 'JAGA-7Q4M-2KXP-9D3F';
  Widget body() => const PauseTokenBody(token: token, onShare: _noop);

  testWidgets('the copied token is cleared after 60 s if still there', (
    tester,
  ) async {
    await mockClipboard(tester);
    await pumpJaga(tester, body());
    await tester.tap(find.byIcon(Icons.copy));
    await tester.pump();
    expect(clip, token);
    await tester.pump(const Duration(seconds: 59));
    expect(clip, token);
    await tester.pump(const Duration(seconds: 2));
    expect(clip, '');
  });

  testWidgets('something else the user copied is left alone', (tester) async {
    await mockClipboard(tester);
    await pumpJaga(tester, body());
    await tester.tap(find.byIcon(Icons.copy));
    await tester.pump();
    clip = 'a phone number';
    await tester.pump(const Duration(seconds: 61));
    expect(clip, 'a phone number');
  });

  testWidgets('leaving the screen clears the token and leaves no timer', (
    tester,
  ) async {
    await mockClipboard(tester);
    await pumpJaga(tester, body());
    await tester.tap(find.byIcon(Icons.copy));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(clip, '');
    await tester.pump(const Duration(seconds: 61));
    expect(tester.takeException(), isNull);
  });
}

void _noop(String _) {}
