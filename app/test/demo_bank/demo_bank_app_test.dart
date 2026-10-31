import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/features/demo_bank/demo_bank_app.dart';
import 'package:jaga/features/demo_bank/pause_client.dart';

class FakePause implements PauseClient {
  FakePause(this.result);
  final Object result; // PauseAnswer or PauseFailure
  final tokens = <String>[];

  @override
  Future<PauseAnswer> ask(String pauseToken) async {
    tokens.add(pauseToken);
    if (result is PauseFailure) throw result;
    return result as PauseAnswer;
  }
}

Future<FakePause> run(WidgetTester tester, Object result) async {
  final fake = FakePause(result);
  await tester.pumpWidget(DemoBankApp(client: fake, pauseToken: 'tok'));
  await tester.enterText(find.widgetWithText(TextField, 'Recipient'), 'Ali');
  await tester.enterText(find.widgetWithText(TextField, 'Amount (RM)'), '500');
  await tester.tap(find.text('Transfer'));
  await tester.pumpAndSettle();
  return fake;
}

void main() {
  testWidgets('held screen asks with the token, shows minutes and agency', (
    t,
  ) async {
    final fake = await run(
      t,
      const PauseAnswer(
        inScam: true,
        recommendedHoldMinutes: 30,
        claimedAgency: 'PDRM',
      ),
    );
    expect(fake.tokens, ['tok']);
    expect(find.text('Transfer held'), findsOneWidget);
    expect(find.textContaining('Held for 30 minutes'), findsOneWidget);
    expect(find.textContaining('PDRM'), findsOneWidget);
    expect(find.textContaining('detected a scam call'), findsOneWidget);
  });

  testWidgets('missing agency shows unknown', (t) async {
    await run(t, const PauseAnswer(inScam: true, recommendedHoldMinutes: 10));
    expect(find.textContaining('unknown'), findsOneWidget);
  });

  testWidgets('not in scam sends the transfer', (t) async {
    await run(t, const PauseAnswer(inScam: false, recommendedHoldMinutes: 0));
    expect(find.textContaining('Transfer sent: RM 500 to Ali'), findsOneWidget);
  });

  testWidgets('error shows message and does not send', (t) async {
    await run(t, const PauseFailure('Could not reach Jaga Pause'));
    expect(find.textContaining('Transfer not sent'), findsOneWidget);
    expect(find.textContaining('Transfer sent'), findsNothing);
  });

  testWidgets('empty form does not ask Jaga Pause', (t) async {
    final gate = Completer<void>();
    await t.pumpWidget(
      DemoBankApp(client: _Slow(gate.future), pauseToken: 'tok'),
    );
    await t.tap(find.text('Transfer'));
    await t.pump();
    expect(find.text('Enter a recipient and an amount.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('unconfigured shows a clear message', (t) async {
    await t.pumpWidget(DemoBankApp());
    expect(find.textContaining('not configured'), findsOneWidget);
  });

  testWidgets('shows a spinner while waiting', (t) async {
    final gate = Completer<void>();
    await t.pumpWidget(
      DemoBankApp(client: _Slow(gate.future), pauseToken: 'tok'),
    );
    await t.enterText(find.widgetWithText(TextField, 'Recipient'), 'Ali');
    await t.enterText(find.widgetWithText(TextField, 'Amount (RM)'), '500');
    await t.tap(find.text('Transfer'));
    await t.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    gate.complete();
    await t.pumpAndSettle();
  });
}

class _Slow implements PauseClient {
  _Slow(this.gate);
  final Future<void> gate;

  @override
  Future<PauseAnswer> ask(String pauseToken) async {
    await gate;
    return const PauseAnswer(inScam: false, recommendedHoldMinutes: 0);
  }
}
