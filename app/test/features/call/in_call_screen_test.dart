import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/core/haptics/fake_buzzer.dart';
import 'package:jaga/core/widgets/big_button.dart';
import 'package:jaga/data/models/call_snapshot.dart';
import 'package:jaga/data/models/stage_update.dart';
import 'package:jaga/data/repositories/call_risk_repository.dart';
import 'package:jaga/data/services/attention_service.dart';
import 'package:jaga/data/services/call_service.dart';
import 'package:jaga/data/services/call_ui_service.dart';
import 'package:jaga/data/services/stage_stream_service.dart';
import 'package:jaga/debug/demo_call_screen.dart';
import 'package:jaga/debug/fixtures/stage_update_fixtures.dart';
import 'package:jaga/features/call/views/in_call_screen.dart';
import 'package:jaga/features/call/views/widgets/call_toggle.dart';
import 'package:jaga/features/warning/view_models/warning_view_model.dart';
import 'package:jaga/features/warning/views/widgets/caution_banner.dart';
import 'package:jaga/features/warning/views/widgets/warning_screen.dart';

import '../../support/harness.dart';

const caller = DemoCallScreen.callerNumber;

class Rig {
  Rig(CallSnapshot snapshot) : service = FakeCallService(snapshot);

  final FakeCallService service;
  final stream = FakeStageStreamService();
  final ui = FakeCallUiService();
  late final warning = WarningViewModel(
    repository: CallRiskRepository(stream),
    buzzer: FakeBuzzer(),
    attention: FakeAttentionService(),
  );

  Widget get screen =>
      DemoCallScreen(warningVm: warning, service: service, callUi: ui);
}

Future<Rig> pump(
  WidgetTester tester,
  CallSnapshot snapshot, {
  double scale = 1.0,
}) async {
  final rig = Rig(snapshot);
  addTearDown(() {
    rig.warning.dispose();
    rig.stream.dispose();
    rig.service.dispose();
  });
  await pumpJaga(tester, rig.screen, scale: scale);
  return rig;
}

CallSnapshot active() => DemoCallScreen.active();

const connecting = CallSnapshot(
  phase: CallPhase.connecting,
  callerLabel: caller,
);

Finder inScreen(Finder f) =>
    find.descendant(of: find.byType(InCallScreen), matching: f);

void main() {
  forEachScale('1 active: everything visible, Hang up above the bottom edge', (
    tester,
    scale,
  ) async {
    await pump(tester, active(), scale: scale);
    expect(find.text('Protecting this call'), findsOneWidget);
    expect(find.text(caller), findsOneWidget);
    expect(find.text('02:14'), findsOneWidget);
    expect(find.text('Mute'), findsOneWidget);
    expect(find.text('Speaker'), findsOneWidget);
    expect(find.text('Hang up'), findsOneWidget);
    // The caller number stays on one line.
    expect(tester.getSize(find.text(caller)).height, lessThan(60 * scale));
    final hang = tester.getRect(find.byType(BigButton));
    expect(hang.bottom, lessThanOrEqualTo(phoneSize.height));
    expect(hang.top, greaterThan(0));
    expect(hang.height, greaterThanOrEqualTo(56));
    for (final label in ['Mute', 'Speaker']) {
      expect(
        tester.getSize(find.widgetWithText(CallToggle, label)).height,
        greaterThanOrEqualTo(56),
      );
    }
    for (final label in ['Mute', 'Speaker']) {
      final r = tester.getRect(find.widgetWithText(CallToggle, label));
      expect(r.bottom, lessThanOrEqualTo(hang.top), reason: label);
      expect(r.top, greaterThan(0), reason: label);
    }
  });

  testWidgets('1 active: Mute and Speaker sit together just above Hang up', (
    tester,
  ) async {
    await pump(tester, active());
    final toggles = find.byType(CallToggle);
    final mute = tester.getRect(toggles.at(0));
    final speaker = tester.getRect(toggles.at(1));
    final hang = tester.getRect(find.byType(BigButton));
    // The free space goes above the controls, not between Mute and the rest.
    expect(speaker.top - mute.bottom, lessThanOrEqualTo(24));
    expect(hang.top - speaker.bottom, lessThanOrEqualTo(48));
  });

  forEachScale('2 connecting: mute and speaker disabled, Hang up enabled', (
    tester,
    scale,
  ) async {
    final rig = await pump(tester, connecting, scale: scale);
    expect(find.text('Connecting…'), findsOneWidget);
    final toggles = tester.widgetList<CallToggle>(find.byType(CallToggle));
    expect(toggles.every((t) => t.onPressed == null), isTrue);
    await tester.tap(find.byType(BigButton));
    await tester.pumpAndSettle();
    expect(rig.service.hangUps, 1);
  });

  forEachScale('2 reconnecting: the call audio message', (tester, scale) async {
    await pump(
      tester,
      active().copyWith(phase: CallPhase.reconnecting),
      scale: scale,
    );
    expect(find.text('Reconnecting the call…'), findsOneWidget);
    final live = tester.getSemantics(find.text('Reconnecting the call…'));
    expect(live.flagsCollection.isLiveRegion, isTrue);
  });

  testWidgets('3 the timer follows connectedAt and reads aloud', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, active());
    expect(find.text('02:14'), findsOneWidget);
    expect(find.bySemanticsLabel('Call time 02:14'), findsOneWidget);
    semantics.dispose();
  });

  forEachScale('4 mute: red button and strip, either one unmutes', (
    tester,
    scale,
  ) async {
    final rig = await pump(tester, active(), scale: scale);
    expect(find.text('Muted: the caller can\'t hear you'), findsNothing);
    await tester.tap(find.widgetWithText(CallToggle, 'Mute'));
    await tester.pumpAndSettle();
    expect(rig.service.mutedCalls, [true]);
    // The button and the strip under the masthead.
    expect(find.text('Muted: the caller can\'t hear you'), findsNWidgets(2));
    final strip = find.byType(InkWell).first;
    expect(tester.getSize(strip).height, greaterThanOrEqualTo(56));
    expect(
      tester.getTopLeft(strip).dy,
      lessThan(tester.getTopLeft(find.text(caller)).dy),
    );
    await tester.tap(strip);
    await tester.pumpAndSettle();
    expect(rig.service.mutedCalls, [true, false]);
    expect(find.text('Muted: the caller can\'t hear you'), findsNothing);

    // The button unmutes too.
    await tester.tap(find.widgetWithText(CallToggle, 'Mute'));
    await tester.pumpAndSettle();
    final muted = find.widgetWithText(
      CallToggle,
      'Muted: the caller can\'t hear you',
    );
    await tester.ensureVisible(muted);
    await tester.tap(muted);
    await tester.pumpAndSettle();
    expect(rig.service.mutedCalls, [true, false, true, false]);
  });

  testWidgets('4 speaker: on is checked and the ear lock is released', (
    tester,
  ) async {
    final rig = await pump(tester, active());
    expect(rig.ui.proximityLock, isTrue); // at the ear
    await tester.tap(find.widgetWithText(CallToggle, 'Speaker'));
    await tester.pumpAndSettle();
    expect(rig.service.speakerCalls, [true]);
    expect(rig.ui.proximityLock, isFalse);
    expect(
      tester
          .getSemantics(find.widgetWithText(CallToggle, 'Speaker'))
          .flagsCollection
          .isToggled
          .name,
      'isTrue',
    );
  });

  testWidgets('the call screen shows over the lock screen and clears it', (
    tester,
  ) async {
    final rig = await pump(tester, active());
    expect(rig.ui.showWhenLocked, isTrue);
    await tester.pumpWidget(const SizedBox());
    expect(rig.ui.showWhenLocked, isFalse);
    expect(rig.ui.proximityLock, isFalse);
  });

  testWidgets('5 Hang up on the call screen: once', (tester) async {
    final rig = await pump(tester, active());
    await tester.tap(find.byType(BigButton));
    await tester.pumpAndSettle();
    expect(rig.service.hangUps, 1);
  });

  testWidgets('5 Hang up on the Warning: once', (tester) async {
    final rig2 = await pump(tester, active());
    rig2.stream.emit(StageUpdate.parse(stageHigh));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(WarningScreen),
        matching: find.byType(BigButton),
      ),
    );
    await tester.pumpAndSettle();
    expect(rig2.service.hangUps, 1);
  });

  testWidgets('6 ended: duration and Done, then it leaves after 3 s', (
    tester,
  ) async {
    final rig = Rig(
      active().copyWith(
        phase: CallPhase.ended,
        endedAt: active().connectedAt!.add(
          const Duration(minutes: 2, seconds: 14),
        ),
      ),
    );
    addTearDown(() {
      rig.warning.dispose();
      rig.stream.dispose();
    });
    await pumpJaga(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () =>
              Navigator.of(context)
                  .push(MaterialPageRoute<void>(builder: (_) => rig.screen)),
          child: const Text('home'),
        ),
      ),
    );
    await tester.tap(find.text('home'));
    await tester.pumpAndSettle();
    expect(find.text('Call ended  02:14'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Mute'), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(InCallScreen), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.byType(InCallScreen), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  forEachScale('6 failed: message, body and Done', (tester, scale) async {
    await pump(
      tester,
      const CallSnapshot(phase: CallPhase.failed, callerLabel: caller),
      scale: scale,
    );
    expect(find.text('The call didn\'t connect'), findsOneWidget);
    expect(find.text('If it matters, they will call again.'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets(
    '7 back: to the background while active, nothing under a Warning',
    (tester) async {
      final rig = await pump(tester, active());
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(rig.ui.movedToBack, 1);
      expect(find.byType(InCallScreen), findsOneWidget);

      rig.stream.emit(StageUpdate.parse(stageHigh));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(rig.ui.movedToBack, 1);
      expect(find.byType(WarningScreen), findsOneWidget);
    },
  );

  testWidgets('7 back after the call returns to the screen before it', (
    tester,
  ) async {
    final rig = Rig(active().copyWith(phase: CallPhase.failed));
    addTearDown(() {
      rig.warning.dispose();
      rig.stream.dispose();
    });
    await pumpJaga(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () =>
              Navigator.of(context)
                  .push(MaterialPageRoute<void>(builder: (_) => rig.screen)),
          child: const Text('home'),
        ),
      ),
    );
    await tester.tap(find.text('home'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(InCallScreen), findsNothing);
  });

  forEachScale('8 medium: the banner over the masthead, controls still work', (
    tester,
    scale,
  ) async {
    final rig = await pump(tester, active(), scale: scale);
    rig.stream.emit(StageUpdate.parse(stageMedium));
    await tester.pumpAndSettle();
    expect(find.byType(CautionBanner), findsOneWidget);
    await tester.tap(find.widgetWithText(CallToggle, 'Mute'));
    await tester.pumpAndSettle();
    expect(rig.service.mutedCalls, [true]);
  });

  forEachScale(
    '8 high: the Warning covers the call, mute and speaker are kept',
    (tester, scale) async {
      final rig = await pump(
        tester,
        active().copyWith(muted: true, speakerOn: true),
        scale: scale,
      );
      rig.stream.emit(StageUpdate.parse(stageHigh));
      await tester.pumpAndSettle();
      expect(find.byType(WarningScreen), findsOneWidget);
      expect(rig.service.mutedCalls, isEmpty);
      expect(rig.service.speakerCalls, isEmpty);
      expect(rig.service.hangUps, 0);
      rig.warning.dismiss();
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(CallToggle, 'Muted: the caller can\'t hear you'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<CallToggle>(find.widgetWithText(CallToggle, 'Speaker'))
            .on,
        isTrue,
      );
    },
  );

  testWidgets('a call with no number shows Unknown number', (tester) async {
    await pump(tester, const CallSnapshot(phase: CallPhase.connecting));
    expect(find.text('Unknown number'), findsOneWidget);
  });
}
