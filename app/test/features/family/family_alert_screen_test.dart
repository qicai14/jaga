import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/core/theme/jaga_colors.dart';
import 'package:jaga/core/widgets/big_button.dart';
import 'package:jaga/core/widgets/stage_progress_bar.dart';
import 'package:jaga/data/models/family_alert.dart';
import 'package:jaga/data/models/linked_person.dart';
import 'package:jaga/data/repositories/family_alert_repository.dart';
import 'package:jaga/data/services/alert_notifier.dart';
import 'package:jaga/data/services/alert_push_service.dart';
import 'package:jaga/data/services/dialer_service.dart';
import 'package:jaga/debug/fixtures/family_alert_fixtures.dart';
import 'package:jaga/features/family/view_models/family_alert_view_model.dart';
import 'package:jaga/features/family/views/family_alert_screen.dart';
import 'package:jaga/features/family/views/widgets/name_band.dart';
import 'package:jaga/features/family/views/widgets/quote_block.dart';

import '../../support/harness.dart';

class Rig {
  Rig(String initial, LinkedPerson person) {
    repo = FamilyAlertRepository(
      push: push,
      notifier: notifier,
      person: person,
    );
    vm = FamilyAlertViewModel(
      repository: repo,
      dialer: dialer,
      initial: FamilyAlert.parse(initial),
    );
  }

  final push = FakeAlertPushService();
  final notifier = FakeAlertNotifier();
  final dialer = FakeDialerService();
  late final FamilyAlertRepository repo;
  late final FamilyAlertViewModel vm;

  void dispose() {
    vm.dispose();
    repo.dispose();
    push.dispose();
    notifier.dispose();
  }
}

Future<Rig> pump(
  WidgetTester tester,
  double scale,
  String initial, {
  LinkedPerson person = familyPerson,
  bool autoDial = false,
}) async {
  final rig = Rig(initial, person);
  addTearDown(rig.dispose);
  await pumpJaga(
    tester,
    FamilyAlertScreen(vm: rig.vm, autoDial: autoDial),
    scale: scale,
  );
  return rig;
}

double top(WidgetTester tester, Finder f) => tester.getTopLeft(f).dy;

final callMum = find.text('Call Mum');
const _quote = '“Jangan beritahu sesiapa tentang kes ini”';

void main() {
  forEachScale(
    '1 alert: headline, stage, agency, summary, quote, then the button',
    (tester, scale) async {
      final handle = tester.ensureSemantics();
      await pump(tester, scale, familyMoney);
      final items = [
        find.text('Mum may be on a scam call'),
        find.text('Asked to move money'),
        find.text('PDRM'),
        find.textContaining('safe account'),
        find.text('“Pindahkan wang ke akaun selamat ini sekarang”'),
        find.text('“Jangan letak telefon”'),
      ];
      final paint = [for (final f in items) top(tester, f)];
      expect(paint, orderedEquals([...paint]..sort()));
      final semantic = [for (final f in items) tester.getSemantics(f).rect.top];
      expect(semantic, orderedEquals([...semantic]..sort()));
      expect(callMum, findsOneWidget);
      handle.dispose();
    },
  );

  forEachScale('2 Call dials the number once', (tester, scale) async {
    final rig = await pump(tester, scale, familyIsolation);
    await tester.tap(callMum);
    await tester.pump();
    expect(rig.dialer.dialed, ['+60 12-345 6789']);
  });

  forEachScale('2b autoDial dials after the first frame, once', (
    tester,
    scale,
  ) async {
    final rig = await pump(tester, scale, familyIsolation, autoDial: true);
    expect(rig.dialer.dialed, ['+60 12-345 6789']);
  });

  forEachScale('3 no number: the button opens the phone app', (
    tester,
    scale,
  ) async {
    final rig = await pump(
      tester,
      scale,
      familyIsolation,
      person: familyPersonNoNumber,
    );
    expect(callMum, findsNothing);
    await tester.tap(find.text('Open the phone app'));
    await tester.pump();
    expect(rig.dialer.dialed, [null]);
  });

  forEachScale('4 no agency, no quotes: those blocks are gone', (
    tester,
    scale,
  ) async {
    await pump(tester, scale, familyNoAgency);
    expect(find.text('The caller says they are from'), findsNothing);
    await pump(tester, scale, familyNoQuotes);
    expect(find.text('The caller said'), findsNothing);
    expect(find.byType(QuoteBlock), findsNothing);
    expect(find.text('LHDN'), findsOneWidget);
  });

  forEachScale('5 long quotes and name: scrolls, the button stays pinned', (
    tester,
    scale,
  ) async {
    await pump(tester, scale, familyLongText, person: familyPersonLongName);
    expect(find.byType(QuoteBlock), findsNWidgets(2));
    final button = find.byType(BigButton);
    final bottom = tester.getRect(button).bottom;
    expect(bottom, lessThanOrEqualTo(phoneSize.height));
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -2000),
    );
    await tester.pump();
    expect(tester.getRect(button).bottom, bottom);
    expect(find.textContaining('menjejaskan kes anda'), findsOneWidget);
  });

  forEachScale('6 may be genuine: blue band, calm body, no quotes', (
    tester,
    scale,
  ) async {
    await pump(tester, scale, familyMayBeGenuine);
    const colors = JagaColors.light;
    expect(find.text("Mum's call may be genuine"), findsOneWidget);
    expect(find.textContaining('less likely to be a scam'), findsOneWidget);
    expect(find.byType(QuoteBlock), findsNothing);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    expect(
      tester
          .widget<AnimatedContainer>(
            find.descendant(
              of: find.byType(NameBand),
              matching: find.byType(AnimatedContainer),
            ),
          )
          .decoration,
      isA<BoxDecoration>().having(
        (d) => d.color,
        'color',
        colors.genuineContainer,
      ),
    );
    expect(callMum, findsOneWidget);
  });

  forEachScale('7 a follow-up swaps the band in place; the stage holds', (
    tester,
    scale,
  ) async {
    final rig = await pump(tester, scale, familyMoney);
    expect(find.text('Mum may be on a scam call'), findsOneWidget);
    expect(find.byType(QuoteBlock), findsNWidgets(2));
    rig.push.emit(FamilyAlert.parse(familyMayBeGenuine));
    await tester.pumpAndSettle();
    expect(find.text("Mum's call may be genuine"), findsOneWidget);
    expect(find.text('Mum may be on a scam call'), findsNothing);
    expect(find.byType(QuoteBlock), findsNothing);
    expect(
      tester.widget<StageProgressBar>(find.byType(StageProgressBar)).stage.name,
      'money',
    );
  });

  forEachScale('8 a late older alert does not lower the stage bar', (
    tester,
    scale,
  ) async {
    final rig = await pump(tester, scale, familyMoney);
    rig.push.emit(FamilyAlert.parse(familyIsolation));
    await tester.pumpAndSettle();
    expect(find.text('Asked to move money'), findsOneWidget);
    expect(find.text('Told to keep it secret'), findsNothing);
  });

  testWidgets('one isolation quote is shown with its marks', (tester) async {
    await pump(tester, 1.0, familyIsolation);
    expect(find.text(_quote), findsOneWidget);
  });
}
