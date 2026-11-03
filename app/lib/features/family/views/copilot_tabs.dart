import 'package:flutter/material.dart';

import '../../../core/l10n/gen/app_localizations.dart';

/// The co-pilot's three tabs (Home, Calls, Settings) behind a bottom bar.
/// Tabs stay alive in an [IndexedStack]; Back on Calls or Settings goes to Home
/// first. No dependencies: the shell owns the index and builds the [tabs].
class CopilotTabs extends StatelessWidget {
  const CopilotTabs({
    super.key,
    required this.index,
    required this.onSelect,
    required this.tabs,
  }) : assert(tabs.length == 3);

  final int index;
  final ValueChanged<int> onSelect;
  final List<Widget> tabs;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PopScope(
      canPop: index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onSelect(0);
      },
      child: Scaffold(
        body: IndexedStack(index: index, children: tabs),
        // Labels are short, so a 1.3 cap keeps three of them on one line at x2.0.
        bottomNavigationBar: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          child: NavigationBar(
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            selectedIndex: index,
            onDestinationSelected: onSelect,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: l.familyNavHome,
              ),
              NavigationDestination(
                icon: const Icon(Icons.history),
                selectedIcon: const Icon(Icons.history),
                label: l.familyNavCalls,
              ),
              NavigationDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings),
                label: l.settingsTitle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
