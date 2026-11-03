import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jaga/features/family/views/copilot_tabs.dart';

import '../../support/harness.dart';

class _Host extends StatefulWidget {
  const _Host();

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  int tab = 0;

  @override
  Widget build(BuildContext context) => CopilotTabs(
    index: tab,
    onSelect: (i) => setState(() => tab = i),
    tabs: const [Text('page-home'), Text('page-calls'), Text('page-set')],
  );
}

const _labels = {
  'en': ['Home', 'Calls', 'Settings'],
  'ms': ['Utama', 'Panggilan', null],
  'zh': ['主页', '通话', null],
};

void main() {
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
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('the selected tab follows the index and keeps the others', (
    tester,
  ) async {
    await pumpJaga(tester, const _Host());
    NavigationBar bar() => tester.widget(find.byType(NavigationBar));
    expect(bar().selectedIndex, 0);
    await tester.tap(find.text('Calls'));
    await tester.pumpAndSettle();
    expect(bar().selectedIndex, 1);
    expect(find.text('page-calls'), findsOneWidget);
    // Kept alive, not rebuilt: the Home page is still in the tree.
    expect(find.text('page-home', skipOffstage: false), findsOneWidget);
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
