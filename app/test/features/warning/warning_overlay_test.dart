import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/core/haptics/fake_buzzer.dart';
import 'package:jaga/core/widgets/big_button.dart';
import 'package:jaga/core/widgets/hold_to_confirm_button.dart';
import 'package:jaga/core/widgets/reconnecting_dot.dart';
import 'package:jaga/data/models/stage_update.dart';
import 'package:jaga/data/repositories/call_risk_repository.dart';
import 'package:jaga/data/services/attention_service.dart';
import 'package:jaga/data/services/stage_stream_service.dart';
import 'package:jaga/debug/fixtures/stage_update_extended_fixtures.dart';
import 'package:jaga/debug/fixtures/stage_update_fixtures.dart';
import 'package:jaga/debug/placeholder_call_screen.dart';
import 'package:jaga/features/warning/view_models/warning_view_model.dart';
import 'package:jaga/features/warning/views/widgets/caution_banner.dart';
import 'package:jaga/features/warning/views/widgets/warning_screen.dart';

import '../../support/harness.dart';

StageUpdate u(String raw) => StageUpdate.parse(raw);

const command = 'Letak telefon sekarang.';
const caller = PlaceholderCallScreen.callerNumber;

class Rig {
  final stream = FakeStageStreamService();
  final buzzer = FakeBuzzer();
  late final vm = WarningViewModel(
    repository: CallRiskRepository(stream),
    buzzer: buzzer,
    attention: FakeAttentionService(),
  );
  int hangUps = 0;

  Widget get host => PlaceholderCallScreen(vm: vm, onHangUp: () => hangUps++);
}

Future<Rig> pump(WidgetTester tester, double scale) async {
  final rig = Rig();
  addTearDown(() {
    rig.vm.dispose();
    rig.stream.dispose();
  });
  await pumpJaga(tester, rig.host, scale: scale);
  return rig;
}

Future<void> emit(WidgetTester tester, Rig rig, String raw) async {
  rig.stream.emit(u(raw));
  await tester.pumpAndSettle();
}

double top(WidgetTester tester, String text) =>
    tester.getTopLeft(find.text(text)).dy;

void main() {
  forEachScale('1 low: nothing from the overlay, call screen unchanged', (
    tester,
    scale,
  ) async {
    final rig = await pump(tester, scale);
    await emit(tester, rig, stageLow);
    expect(find.byType(CautionBanner), findsNothing);
    expect(find.byType(WarningScreen), findsNothing);
    expect(find.text(caller), findsOneWidget);
    expect(rig.buzzer.calls, isEmpty);
  });

  forEachScale('2 medium: banner, no command, no buzz', (tester, scale) async {
    final rig = await pump(tester, scale);
    await emit(tester, rig, stageMedium);
    expect(find.text('This call has signs of a scam'), findsOneWidget);
    expect(find.byType(WarningScreen), findsNothing);
    expect(find.text(command), findsNothing);
    expect(rig.buzzer.calls, isEmpty);
    // The banner stays within about 40% of the height.
    expect(
      tester.getSize(find.byType(CautionBanner)).height,
      lessThanOrEqualTo(phoneSize.height * 0.42),
    );
  });

  forEachScale(
    '3 high: command, English, counter-move, number, evidence in order',
    (tester, scale) async {
      final handle = tester.ensureSemantics();
      final rig = await pump(tester, scale);
      await emit(tester, rig, extHigh);
      expect(rig.buzzer.startCount, 1);

      final texts = [
        command,
        'Hang up now.',
        'Polis tidak akan minta wang atau kata laluan melalui telefon. Hubungi PDRM sendiri.',
        "PDRM's official number",
        '+60 3-2266 2222',
        'The caller said',
        '“Akaun anda dikaitkan dengan satu kes jenayah”',
      ];
      // The scroll region may clip lower items at 2.0 but they are still in the tree.
      final paint = [for (final t in texts) top(tester, t)];
      expect(paint, orderedEquals([...paint]..sort()));
      final semantic = [
        for (final t in texts) tester.getSemantics(find.text(t)).rect.top,
      ];
      expect(semantic, orderedEquals([...semantic]..sort()));
      handle.dispose();
    },
  );

  // Note: flutter_test lays text out in Ahem (every glyph 1em wide), roughly 1.6x
  // wider than Noto Sans, so these are worst-case sizes.
  forEachScale('4 high, 73-character command and English: never below 32sp', (
    tester,
    scale,
  ) async {
    final rig = await pump(tester, scale);
    await emit(tester, rig, extHighLongText);
    final cmd = (u(extHighLongText).command)!;
    final style = tester.widget<Text>(find.text(cmd)).style!;
    expect(style.fontSize, greaterThanOrEqualTo(32));
    // Both buttons stay reachable.
    expect(
      tester.getRect(find.byType(HoldToConfirmButton)).bottom,
      lessThanOrEqualTo(phoneSize.height),
    );
  });

  forEachScale('4b high, 56-character command: fits without scrolling at 1.0', (
    tester,
    scale,
  ) async {
    final rig = await pump(tester, scale);
    const long = 'Berhenti dan letak telefon sekarang, jangan pindah wang!';
    await emit(
      tester,
      rig,
      extHigh
          .replaceAll('Letak telefon sekarang.', long)
          .replaceAll('"commandEnglish": "Hang up now.",', ''),
    );
    final style = tester.widget<Text>(find.text(long)).style!;
    expect(style.fontSize, greaterThanOrEqualTo(32));
    if (scale == 1.0) {
      // Region 2 never scrolls when the command can fit.
      expect(
        find.ancestor(of: find.text(long), matching: find.byType(Scrollable)),
        findsNothing,
      );
    }
  });

  forEachScale('5 credentials: hand icon, no evidence', (tester, scale) async {
    final rig = await pump(tester, scale);
    await emit(tester, rig, extHighCredentials);
    expect(find.text('Jangan beritahu kod atau kata laluan.'), findsOneWidget);
    expect(find.byIcon(Icons.pan_tool), findsOneWidget);
    expect(find.text('The caller said'), findsNothing);
    expect(find.textContaining('Sila beritahu'), findsNothing);
  });

  forEachScale('5b no command at high: safety-net command', (
    tester,
    scale,
  ) async {
    final rig = await pump(tester, scale);
    await emit(tester, rig, stageHighNoCommand);
    expect(find.text('Letak telefon. Hang up.'), findsOneWidget);
    expect(find.text('Hang up'), findsOneWidget); // the button
  });

  forEachScale('5c no official number: its label and number are hidden', (
    tester,
    scale,
  ) async {
    final rig = await pump(tester, scale);
    await emit(tester, rig, extHighNoNumber);
    expect(find.textContaining('official number'), findsNothing);
    expect(find.text('Official number'), findsNothing);
    expect(find.text(command), findsOneWidget);
  });

  forEachScale('6 English-only phrase: command shown once', (
    tester,
    scale,
  ) async {
    final rig = await pump(tester, scale);
    await emit(tester, rig, extHighEnglishOnly);
    expect(find.text('Hang up now.'), findsOneWidget);
  });

  forEachScale('7 hold 1 s keeps it; hold 2 s dismisses locally', (
    tester,
    scale,
  ) async {
    final rig = await pump(tester, scale);
    await emit(tester, rig, extHigh);
    final button = find.byType(HoldToConfirmButton);

    var g = await tester.startGesture(tester.getCenter(button));
    await tester.pump(); // the ticker starts on the first frame
    await tester.pump(const Duration(seconds: 1));
    await g.up();
    await tester.pumpAndSettle();
    expect(find.byType(WarningScreen), findsOneWidget);

    g = await tester.startGesture(tester.getCenter(button));
    await tester.pump(); // the ticker starts on the first frame
    await tester.pump(const Duration(milliseconds: 2100));
    await g.up();
    await tester.pumpAndSettle();
    expect(find.byType(WarningScreen), findsNothing);
    expect(rig.buzzer.buzzing, isFalse);
    expect(find.text(caller), findsOneWidget);
    // Dismiss is local: the repository has no write API, and the stream is still
    // listened to (test 8).
  });

  forEachScale(
    '8 dismissed: same update stays hidden, a new stage brings it back',
    (tester, scale) async {
      final rig = await pump(tester, scale);
      await emit(tester, rig, extHigh);
      rig.vm.dismiss();
      await tester.pumpAndSettle();
      await emit(tester, rig, extHigh);
      expect(find.byType(WarningScreen), findsNothing);
      await emit(tester, rig, extHighCredentials);
      expect(find.byType(WarningScreen), findsOneWidget);
      expect(rig.buzzer.startCount, 2);
    },
  );

  forEachScale('9 high to medium to low', (tester, scale) async {
    final rig = await pump(tester, scale);
    await emit(tester, rig, extHigh);
    await emit(tester, rig, stageMedium);
    expect(find.byType(CautionBanner), findsOneWidget);
    expect(find.byType(WarningScreen), findsNothing);
    expect(rig.buzzer.buzzing, isFalse);
    await emit(tester, rig, stageLow);
    expect(find.byType(CautionBanner), findsNothing);
  });

  forEachScale('10 disconnected: content frozen, dot with a label', (
    tester,
    scale,
  ) async {
    final handle = tester.ensureSemantics();
    final rig = await pump(tester, scale);
    await emit(tester, rig, extHigh);
    expect(find.bySemanticsLabel('Reconnecting'), findsNothing);
    rig.stream.setConnected(false);
    await tester.pumpAndSettle();
    await emit(tester, rig, extHigh.replaceAll(command, 'Jangan percaya.'));
    expect(find.text(command), findsOneWidget);
    expect(find.text('Jangan percaya.'), findsNothing);
    expect(find.bySemanticsLabel('Reconnecting'), findsOneWidget);
    expect(
      tester.widget<ReconnectingDot>(find.byType(ReconnectingDot)).visible,
      isTrue,
    );
    rig.stream.setConnected(true);
    await tester.pumpAndSettle();
    expect(find.text('Jangan percaya.'), findsOneWidget);
    handle.dispose();
  });

  forEachScale('11 system back does nothing while the Warning is up', (
    tester,
    scale,
  ) async {
    final rig = Rig();
    addTearDown(() {
      rig.vm.dispose();
      rig.stream.dispose();
    });
    await pumpJaga(tester, const SizedBox(), scale: scale);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push(MaterialPageRoute<void>(builder: (_) => rig.host));
    await tester.pumpAndSettle();

    await emit(tester, rig, extHigh);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(WarningScreen), findsOneWidget);
    expect(find.text(caller), findsOneWidget);

    rig.vm.dismiss();
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text(caller), findsNothing);
  });

  forEachScale('12 animations off: fully shown after one pump', (
    tester,
    scale,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final rig = await pump(tester, scale);
    rig.stream.emit(u(extHigh));
    await tester.pump();
    expect(find.text(command), findsOneWidget);
    final opacity = tester.widget<Opacity>(
      find.descendant(
        of: find.byType(WarningScreen),
        matching: find.byType(Opacity),
      ),
    );
    expect(opacity.opacity, 1);
  });

  forEachScale('13 hang up tapped: onHangUp once', (tester, scale) async {
    final rig = await pump(tester, scale);
    await emit(tester, rig, extHigh);
    await tester.tap(find.byType(BigButton));
    await tester.pump();
    expect(rig.hangUps, 1);
  });

  forEachScale('touching the Warning stops the buzz', (tester, scale) async {
    final rig = await pump(tester, scale);
    await emit(tester, rig, extHigh);
    expect(rig.buzzer.buzzing, isTrue);
    await tester.tapAt(const Offset(200, 300));
    await tester.pump();
    expect(rig.buzzer.buzzing, isFalse);
  });

  testWidgets(
    'Warning has the spoken label, is not a live region, and hides the call screen',
    (tester) async {
      final handle = tester.ensureSemantics();
      final rig = await pump(tester, 1.0);
      await emit(tester, rig, extHigh);
      expect(find.bySemanticsLabel('Scam warning'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Scam warning')),
        isNot(matchesSemantics(isLiveRegion: true)),
      );
      expect(
        tester
            .widget<ExcludeSemantics>(
              find
                  .ancestor(
                    of: find.text(caller),
                    matching: find.byType(ExcludeSemantics),
                  )
                  .first,
            )
            .excluding,
        isTrue,
      );
      rig.vm.dismiss();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ExcludeSemantics>(
              find
                  .ancestor(
                    of: find.text(caller),
                    matching: find.byType(ExcludeSemantics),
                  )
                  .first,
            )
            .excluding,
        isFalse,
      );
      handle.dispose();
    },
  );
}
