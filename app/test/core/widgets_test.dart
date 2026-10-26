import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/core/theme/theme_context.dart';
import 'package:jaga/core/widgets/big_button.dart';
import 'package:jaga/core/widgets/hold_to_confirm_button.dart';
import 'package:jaga/core/widgets/reconnecting_dot.dart';
import 'package:jaga/core/widgets/screen_frame.dart';
import 'package:jaga/core/widgets/shrink_to_fit_text.dart';
import 'package:jaga/core/widgets/stage_progress_bar.dart';
import 'package:jaga/core/widgets/status_badge.dart';
import 'package:jaga/data/models/stage.dart';

import '../support/harness.dart';

void main() {
  const long =
      'A very long label that has to wrap onto several lines and never ellipsize';

  group('BigButton', () {
    forEachScale('wraps long label, full width, taps', (tester, scale) async {
      var taps = 0;
      await pumpJaga(
        tester,
        ScreenFrame(
          body: const SizedBox(),
          bottomAction: BigButton(label: long, onPressed: () => taps++),
        ),
        scale: scale,
      );
      final size = tester.getSize(find.byType(FilledButton));
      expect(size.height, greaterThanOrEqualTo(64));
      expect(size.width, 393 - 48);
      await tester.tap(find.byType(FilledButton));
      expect(taps, 1);
    });

    forEachScale('every tone renders', (tester, scale) async {
      await pumpJaga(
        tester,
        ScreenFrame(
          body: Column(children: [
            for (final t in BigButtonTone.values)
              BigButton(label: 'x', icon: Icons.phone, tone: t, onPressed: () {}),
          ]),
        ),
        scale: scale,
      );
      expect(find.byType(BigButton), findsNWidgets(4));
    });
  });

  group('HoldToConfirmButton', () {
    Widget host(VoidCallback onConfirmed) => ScreenFrame(
          body: const SizedBox(),
          bottomAction: HoldToConfirmButton(
            label: 'This call is fine',
            secondLabel: 'Keep holding',
            onConfirmed: onConfirmed,
          ),
        );

    forEachScale('hold 1 s and release does not confirm; hold 2 s does',
        (tester, scale) async {
      var n = 0;
      await pumpJaga(tester, host(() => n++), scale: scale);
      final centre = tester.getCenter(find.byType(HoldToConfirmButton));
      final g = await tester.startGesture(centre);
      await tester.pump(); // the ticker starts on the first frame
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Keep holding'), findsOneWidget);
      await g.up();
      await tester.pumpAndSettle();
      expect(n, 0);
      expect(find.text('This call is fine'), findsOneWidget);

      final g2 = await tester.startGesture(centre);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2100));
      await g2.up();
      await tester.pumpAndSettle();
      expect(n, 1);
    });

    testWidgets('TalkBack: two semantic taps confirm, one does not',
        (tester) async {
      final handle = tester.ensureSemantics();
      var n = 0;
      await pumpJaga(tester, host(() => n++));
      tester.semantics.tap(find.semantics.byLabel('This call is fine'));
      await tester.pump();
      expect(n, 0);
      expect(tester.getSemantics(find.byType(HoldToConfirmButton)).hint,
          'Tap again to confirm');
      tester.semantics.tap(find.semantics.byLabel('This call is fine'));
      await tester.pump();
      expect(n, 1);
      handle.dispose();
    });

    testWidgets('TalkBack: arming expires after 5 s', (tester) async {
      final handle = tester.ensureSemantics();
      var n = 0;
      await pumpJaga(tester, host(() => n++));
      tester.semantics.tap(find.semantics.byLabel('This call is fine'));
      await tester.pump(const Duration(seconds: 6));
      tester.semantics.tap(find.semantics.byLabel('This call is fine'));
      await tester.pump();
      expect(n, 0);
      await tester.pump(const Duration(seconds: 6));
      handle.dispose();
    });

    testWidgets('semantics: button with hold hint', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpJaga(tester, host(() {}));
      final node = tester.getSemantics(find.byType(HoldToConfirmButton));
      expect(node.label, 'This call is fine');
      expect(node.hint, 'Hold for 2 seconds');
      handle.dispose();
    });
  });

  group('StatusBadge', () {
    forEachScale('is at least 40 tall and wraps', (tester, scale) async {
      await pumpJaga(
        tester,
        ScreenFrame(
          body: Column(children: [
            for (final t in BadgeTone.values)
              StatusBadge(label: long, tone: t, icon: Icons.shield),
          ]),
        ),
        scale: scale,
      );
      for (var i = 0; i < BadgeTone.values.length; i++) {
        expect(tester.getSize(find.byType(StatusBadge).at(i)).height,
            greaterThanOrEqualTo(40));
      }
    });
  });

  group('StageProgressBar', () {
    forEachScale('every stage renders with label', (tester, scale) async {
      await pumpJaga(
        tester,
        ScreenFrame(
          body: Column(children: [
            for (final s in Stage.values) StageProgressBar(stage: s),
            const StageProgressBar(stage: Stage.money, compact: true),
          ]),
        ),
        scale: scale,
      );
      expect(find.text('Asked to move money'), findsOneWidget);
      expect(find.text('Asked for codes or passwords'), findsOneWidget);
    });

    testWidgets('semantics reads step of 7', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpJaga(tester,
          const ScreenFrame(body: StageProgressBar(stage: Stage.isolation)));
      expect(find.bySemanticsLabel('Step 4 of 7: Told to keep it secret'),
          findsOneWidget);
      handle.dispose();
    });

    testWidgets('localised in Malay', (tester) async {
      await pumpJaga(
        tester,
        const ScreenFrame(body: StageProgressBar(stage: Stage.money)),
        locale: const Locale('ms'),
      );
      expect(find.text('Disuruh memindahkan wang'), findsOneWidget);
    });
  });

  group('ReconnectingDot', () {
    forEachScale('visible dot has a 48dp area and a label', (tester, scale) async {
      final handle = tester.ensureSemantics();
      await pumpJaga(
        tester,
        const ScreenFrame(body: Row(children: [ReconnectingDot(visible: true)])),
        scale: scale,
      );
      expect(tester.getSize(find.byType(ReconnectingDot)), const Size(48, 48));
      expect(find.bySemanticsLabel('Reconnecting'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('hidden dot keeps its space and says nothing', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpJaga(
        tester,
        const ScreenFrame(body: Row(children: [ReconnectingDot(visible: false)])),
      );
      expect(tester.getSize(find.byType(ReconnectingDot)), const Size(48, 48));
      expect(find.bySemanticsLabel('Reconnecting'), findsNothing);
      handle.dispose();
    });
  });

  group('ShrinkToFitText', () {
    forEachScale('shrinks to fit a box, never below the floor',
        (tester, scale) async {
      await pumpJaga(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 345,
                height: 300,
                child: ShrinkToFitText(
                  text: 'Letak telefon sekarang. Jangan bayar apa-apa wang.',
                  style: context.jagaText.command,
                ),
              ),
            ),
          ),
        ),
        scale: scale,
      );
      final size = tester.widget<Text>(find.byType(Text)).style!.fontSize!;
      expect(size, lessThan(52));
      expect(size, greaterThanOrEqualTo(32));
      expect(tester.getSize(find.byType(Text)).height, lessThanOrEqualTo(300.5));
    });

    testWidgets('reports overflow at the floor', (tester) async {
      var overflowed = false;
      await pumpJaga(
        tester,
        Scaffold(
          body: SizedBox(
            width: 200,
            height: 40,
            child: ShrinkToFitText(
              text: 'Letak telefon sekarang. Jangan bayar apa-apa wang.',
              style: const TextStyle(fontSize: 52),
              onOverflow: () => overflowed = true,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.widget<Text>(find.byType(Text)).style!.fontSize, 32);
      expect(overflowed, isTrue);
    });

    testWidgets('keeps full size when it already fits', (tester) async {
      await pumpJaga(
        tester,
        const Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: ShrinkToFitText(text: 'Hi', style: TextStyle(fontSize: 52)),
          ),
        ),
      );
      expect(tester.widget<Text>(find.byType(Text)).style!.fontSize, 52);
    });
  });

  group('ScreenFrame', () {
    forEachScale('title, scrolling body, pinned action', (tester, scale) async {
      await pumpJaga(
        tester,
        ScreenFrame(
          title: 'Title',
          body: Column(children: [for (var i = 0; i < 30; i++) Text('line $i')]),
          bottomAction: BigButton(label: 'Go', onPressed: () {}),
        ),
        scale: scale,
      );
      expect(tester.getTopLeft(find.text('Title')).dx, 24);
      expect(find.byType(BigButton), findsOneWidget);
      expect(tester.getBottomRight(find.byType(BigButton)).dy, lessThanOrEqualTo(852));
    });
  });
}
