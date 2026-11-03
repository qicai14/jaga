import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/features/family/views/copilot_tabs.dart';

import '../../support/harness.dart';

/// A tab with state of its own, to show tabs are kept alive.
class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int n = 0;

  @override
  Widget build(BuildContext context) =>
      TextButton(onPressed: () => setState(() => n++), child: Text('count $n'));
}

class _Host extends StatefulWidget {
  const _Host({
    this.tabs = const [Text('page-home'), Text('page-calls'), Text('page-set')],
  });

  final List<Widget> tabs;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  int tab = 0;

  @override
  Widget build(BuildContext context) => CopilotTabs(
    index: tab,
    onSelect: (i) => setState(() => tab = i),
    tabs: widget.tabs,
  );
}

const _labels = {
  'en': ['Home', 'Calls', 'Settings'],
  'ms': ['Utama', 'Panggilan', null],
  'zh': ['主页', '通话', null],
};

Future<void> _load(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    final bytes = File('assets/fonts/$f').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

/// Line counts need the real fonts: the default test font, Ahem, is far wider.
void main() {
  setUpAll(() async {
    await _load('NotoSans', [
      'NotoSans-Regular.ttf',
      'NotoSans-SemiBold.ttf',
      'NotoSans-ExtraBold.ttf',
    ]);
    await _load('NotoSansSC', [
      'NotoSansSC-Regular.otf',
      'NotoSansSC-Bold.otf',
    ]);
  });

  for (final locale in ['en', 'ms', 'zh']) {
    for (final scale in textScales) {
      testWidgets('three labels, 56dp each, no overflow ($locale x$scale)', (
        tester,
      ) async {
        await pumpJaga(
          tester,
          const _Host(),
          scale: scale,
          locale: Locale(locale),
        );
        final names = _labels[locale]!;
        for (final name in names.whereType<String>()) {
          expect(find.text(name), findsOneWidget);
        }
        expect(find.byType(NavigationDestination), findsNWidgets(3));
        for (final d in tester.widgetList(find.byType(NavigationDestination))) {
          final size = tester.getSize(find.byWidget(d));
          expect(size.height, greaterThanOrEqualTo(56));
          expect(size.width, greaterThanOrEqualTo(56));
        }
        // The selected label is bold, hence wider: check each tab selected.
        for (var sel = 0; sel < 3; sel++) {
          await tester.tap(find.byType(NavigationDestination).at(sel));
          await tester.pumpAndSettle();
          // Wrapping is not overflow: every label must also be one line, and
          // the icon, indicator and label must sit inside the bar.
          final bar = tester.getRect(find.byType(NavigationBar));
          for (var i = 0; i < names.length; i++) {
            final text = find.descendant(
              of: find.byType(NavigationDestination).at(i),
              matching: find.byType(Text),
            );
            final paragraph = tester.renderObject<RenderParagraph>(text);
            final label = paragraph.text.toPlainText();
            // The same text laid out on one unbounded line is the reference.
            final oneLine = TextPainter(
              text: paragraph.text,
              textDirection: TextDirection.ltr,
              textScaler: paragraph.textScaler,
            )..layout();
            expect(
              paragraph.size.height,
              closeTo(oneLine.height, 1),
              reason: '$locale x$scale selected $sel label "$label" wrapped',
            );
            expect(tester.getRect(text).bottom, lessThanOrEqualTo(bar.bottom));
            final icon = tester.getRect(
              find.descendant(
                of: find.byType(NavigationDestination).at(i),
                matching: find.byType(Icon),
              ),
            );
            expect(icon.top, greaterThanOrEqualTo(bar.top));
            expect(icon.bottom, lessThanOrEqualTo(bar.bottom));
          }
          final selected = tester.getRect(
            find.descendant(
              of: find.byType(NavigationDestination).at(sel),
              matching: find.byType(NavigationIndicator),
            ),
          );
          expect(selected.top, greaterThanOrEqualTo(bar.top));
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('a tab keeps its state while another tab shows', (tester) async {
    await pumpJaga(
      tester,
      const _Host(tabs: [_Counter(), Text('c'), Text('s')]),
    );
    NavigationBar bar() => tester.widget(find.byType(NavigationBar));
    expect(bar().selectedIndex, 0);
    await tester.tap(find.text('count 0'));
    await tester.pump();
    expect(find.text('count 1'), findsOneWidget);
    await tester.tap(find.text('Calls'));
    await tester.pumpAndSettle();
    expect(bar().selectedIndex, 1);
    expect(find.text('count 1'), findsNothing); // offstage, not shown
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('count 1'), findsOneWidget); // not rebuilt from zero
  });

  testWidgets('Back on a tab selects Home; Back on Home pops', (tester) async {
    await pumpJaga(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context)
                .push<void>(MaterialPageRoute(builder: (_) => const _Host())),
            child: const Text('root'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('root'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calls'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('page-home'), findsOneWidget);
    expect(find.text('root'), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('root'), findsOneWidget);
  });
}
