import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/core/widgets/hold_to_confirm_button.dart';
import 'package:jaga/data/services/copilot_pause_service.dart';
import 'package:jaga/data/services/dialer_service.dart';
import 'package:jaga/data/services/timeline_service.dart';
import 'package:jaga/debug/fixtures/family_alert_fixtures.dart';
import 'package:jaga/debug/fixtures/timeline_fixtures.dart';
import 'package:jaga/features/family/view_models/copilot_home_view_model.dart';
import 'package:jaga/features/family/view_models/stage_timeline_view_model.dart';
import 'package:jaga/features/family/views/copilot_home_screen.dart';
import 'package:jaga/features/family/views/widgets/alerted_call_tile.dart';
import 'package:jaga/features/family/views/widgets/quote_block.dart';
import 'package:jaga/features/family/views/widgets/timeline_event_row.dart';

import '../../support/harness.dart';

class Rig {
  Rig({bool pauseActive = true, FakeTimelineService? timeline})
    : pause = FakeCopilotPauseService(active: pauseActive),
      timeline = timeline ?? fixtureTimelineService() {
    vm = CopilotHomeViewModel(
      person: familyPerson,
      pause: pause,
      timeline: this.timeline,
    );
  }

  final FakeCopilotPauseService pause;
  final FakeTimelineService timeline;
  final dialer = FakeDialerService();
  late final CopilotHomeViewModel vm;

  Widget get screen => CopilotHomeScreen(
    vm: vm,
    pause: pause,
    timelineFor: (call) =>
        StageTimelineViewModel(call: call, timeline: timeline, dialer: dialer),
    createSettings: () => throw UnimplementedError('covered in app_test'),
  );
}

Future<Rig> pump(
  WidgetTester tester,
  double scale, {
  bool pauseActive = true,
  FakeTimelineService? timeline,
  bool offline = false,
}) async {
  final rig = Rig(pauseActive: pauseActive, timeline: timeline);
  rig.timeline.offline = offline;
  addTearDown(rig.vm.dispose);
  await pumpJaga(tester, rig.screen, scale: scale);
  return rig;
}

Future<void> hold(WidgetTester tester) async {
  final g = await tester.startGesture(
    tester.getCenter(find.byType(HoldToConfirmButton)),
  );
  await tester.pump(); // the ticker starts on the first frame
  await tester.pump(const Duration(milliseconds: 2100));
  await g.up();
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
}

final clearPause = find.text('Clear Jaga Pause');
const _deleteTooltip = 'Delete';

void main() {
  forEachScale('home with Jaga Pause active: card, badges, button, calls', (
    tester,
    scale,
  ) async {
    await pump(tester, scale);
    expect(find.text('Jaga'), findsOneWidget);
    expect(find.text('Mum'), findsOneWidget);
    expect(find.text('Protected'), findsOneWidget);
    expect(find.text('Jaga Pause active'), findsOneWidget);
    expect(clearPause, findsOneWidget);
    expect(find.text('Alerted calls'), findsOneWidget);
    expect(find.byType(AlertedCallTile, skipOffstage: false), findsNWidgets(5));
  });

  forEachScale('home without a pause: no badge, no Clear button', (
    tester,
    scale,
  ) async {
    await pump(tester, scale, pauseActive: false);
    expect(find.text('Protected'), findsOneWidget);
    expect(find.text('Jaga Pause active'), findsNothing);
    expect(clearPause, findsNothing);
  });

  forEachScale('home with no alerted calls says so', (tester, scale) async {
    await pump(tester, scale, timeline: FakeTimelineService());
    expect(find.text('No alerted calls in the last 30 days.'), findsOneWidget);
    expect(find.byType(AlertedCallTile), findsNothing);
  });

  forEachScale('home error offers Try again, which reloads', (
    tester,
    scale,
  ) async {
    final rig = await pump(tester, scale, offline: true);
    expect(
      find.text("Couldn't load calls. Check your internet."),
      findsOneWidget,
    );
    rig.timeline.offline = false;
    await tapVisible(tester, find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Try again'), findsNothing);
    expect(find.byType(AlertedCallTile), findsWidgets);
  });

  forEachScale('many calls scroll without overflow', (tester, scale) async {
    await pump(tester, scale, timeline: fixtureTimelineService(many: true));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -5000));
    await tester.pump();
    expect(find.byType(AlertedCallTile), findsWidgets);
  });

  forEachScale(
    'hold to clear: the sheet closes, the badge goes, a SnackBar shows',
    (tester, scale) async {
      final rig = await pump(tester, scale);
      await tester.tap(clearPause);
      await tester.pumpAndSettle();
      expect(
        find.text("I've spoken to Mum and checked this transfer is genuine."),
        findsOneWidget,
      );
      await hold(tester);
      expect(rig.pause.active, isFalse);
      expect(find.byType(HoldToConfirmButton), findsNothing);
      expect(find.text('Jaga Pause active'), findsNothing);
      expect(clearPause, findsNothing);
      expect(find.text('Jaga Pause cleared'), findsOneWidget);
    },
  );

  forEachScale('a failed clear keeps the sheet open and says why', (
    tester,
    scale,
  ) async {
    final rig = await pump(tester, scale);
    await tester.tap(clearPause);
    await tester.pumpAndSettle();
    rig.pause.offline = true;
    await hold(tester);
    expect(find.byType(HoldToConfirmButton), findsOneWidget);
    expect(
      find.text(
        "Couldn't clear Jaga Pause. Check your internet and try again.",
      ),
      findsOneWidget,
    );
    expect(find.text('Jaga Pause cleared'), findsNothing);
    expect(rig.pause.active, isTrue);
  });

  forEachScale('a tile opens the timeline: steps, risk changes, hotline', (
    tester,
    scale,
  ) async {
    final rig = await pump(tester, scale);
    final tile = find.byType(AlertedCallTile, skipOffstage: false).last;
    await tester.ensureVisible(tile); // call-1, the oldest
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(find.textContaining('Call on'), findsOneWidget);
    expect(
      find.byType(TimelineEventRow, skipOffstage: false),
      findsNWidgets(4),
    );
    // Low at the start shows no badge; medium and high do; high again does not.
    expect(find.text('Caution shown', skipOffstage: false), findsOneWidget);
    expect(find.text('Warning shown', skipOffstage: false), findsOneWidget);
    expect(find.text('Call 997 to report'), findsOneWidget);
    await tester.tap(find.text('Call 997 to report'));
    await tester.pump();
    expect(rig.dialer.dialed, ['997']);
  });

  forEachScale('long quotes on the timeline scroll without overflow', (
    tester,
    scale,
  ) async {
    await pump(tester, scale);
    await tapVisible(tester, find.byType(AlertedCallTile).first); // call-5
    await tester.pumpAndSettle();
    expect(find.byType(QuoteBlock, skipOffstage: false), findsNWidgets(3));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
    await tester.pump();
    expect(find.text('Call 997 to report'), findsOneWidget);
  });

  forEachScale('delete asks first, then pops with a SnackBar', (
    tester,
    scale,
  ) async {
    final rig = await pump(tester, scale);
    await tapVisible(tester, find.byType(AlertedCallTile).first); // call-5
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(_deleteTooltip));
    await tester.pumpAndSettle();
    expect(
      find.text("Delete this timeline? It can't be brought back."),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(rig.timeline.deleted, isEmpty);

    await tester.tap(find.byTooltip(_deleteTooltip));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(rig.timeline.deleted, ['call-5']);
    expect(find.text('Timeline deleted'), findsOneWidget);
    expect(find.text('Alerted calls'), findsOneWidget);
    expect(find.byType(AlertedCallTile, skipOffstage: false), findsNWidgets(4));
  });

  forEachScale('a failed delete stays on the timeline and says so', (
    tester,
    scale,
  ) async {
    final rig = await pump(tester, scale);
    await tapVisible(tester, find.byType(AlertedCallTile).first);
    await tester.pumpAndSettle();
    rig.timeline.offline = true;
    await tester.tap(find.byTooltip(_deleteTooltip));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Call on'), findsOneWidget);
    expect(find.textContaining("Couldn't delete the timeline"), findsOneWidget);
  });

  forEachScale('the timeline error offers Try again', (tester, scale) async {
    final rig = await pump(tester, scale);
    rig.timeline.offline = true; // the list is already loaded
    await tapVisible(tester, find.byType(AlertedCallTile).first);
    await tester.pumpAndSettle();
    expect(
      find.text("Couldn't load this timeline. Check your internet."),
      findsOneWidget,
    );
    rig.timeline.offline = false;
    await tapVisible(tester, find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.byType(TimelineEventRow), findsWidgets);
  });
}
