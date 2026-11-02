import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/data/models/stage_update.dart';
import 'package:jaga/data/services/stage_stream_service.dart';
import 'package:jaga/debug/entries/live_call_entries.dart';
import 'package:jaga/debug/fixtures/stage_update_fixtures.dart';
import 'package:jaga/features/warning/views/widgets/caution_banner.dart';
import 'package:jaga/features/warning/views/widgets/warning_screen.dart';

import '../support/harness.dart';

void main() {
  testWidgets('follows a call: Caution then Warning, Stop closes', (
    tester,
  ) async {
    final stream = FakeStageStreamService();
    addTearDown(stream.dispose);
    await pumpJaga(tester, Scaffold(body: LiveCallFollower(stream: stream)));

    await tester.enterText(find.byType(TextField), 'call-1');
    await tester.tap(find.text('Follow'));
    await tester.pump();
    await tester.pump();
    expect(stream.connectedCalls, ['call-1']);

    stream.emit(StageUpdate.parse(stageMedium));
    await tester.pump();
    expect(find.byType(CautionBanner), findsOneWidget);

    stream.emit(StageUpdate.parse(stageHigh));
    await tester.pump();
    expect(find.byType(WarningScreen), findsOneWidget);

    await tester.tap(find.text('Stop'));
    await tester.pump();
    expect(stream.closeCount, greaterThan(0));
  });
}
