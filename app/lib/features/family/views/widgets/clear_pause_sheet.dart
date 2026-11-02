import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/big_button.dart';
import '../../../../core/widgets/hold_to_confirm_button.dart';
import '../../view_models/clear_pause_view_model.dart';

/// Bottom sheet that asks the co-pilot to hold to clear Jaga Pause. Pops true
/// once it is cleared; on failure it stays open and says so.
class ClearPauseSheet extends StatelessWidget {
  const ClearPauseSheet({super.key, required this.vm});

  final ClearPauseViewModel vm;

  Future<void> _clear(BuildContext context) async {
    final cleared = await vm.clear();
    if (cleared && context.mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = context.metrics;
    final text = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: vm,
      // Closing mid-request would hide the outcome from the co-pilot.
      builder: (context, _) => PopScope(
        canPop: !vm.busy,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(m.l),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Only as tall as its text (the barrier above stays tappable);
                // large text scrolls here and the button stays in reach. A
                // failure comes first: it is the news.
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      if (vm.failed) ...[
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            l.familyClearPauseError,
                            style: text.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                        SizedBox(height: m.m),
                      ],
                      Text(
                        l.familyClearPauseStatement(vm.personName),
                        style: text.bodyLarge,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: m.l),
                if (vm.busy)
                  BigButton(
                    label: l.familyClearPause,
                    busy: true,
                    onPressed: null,
                  )
                else
                  HoldToConfirmButton(
                    label: l.familyClearPauseHold,
                    onConfirmed: () => _clear(context),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
