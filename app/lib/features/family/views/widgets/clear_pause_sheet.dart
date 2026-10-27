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
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(m.l, 0, m.l, m.l),
        child: ListenableBuilder(
          listenable: vm,
          builder: (context, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.familyClearPauseStatement(vm.personName),
                style: text.bodyLarge,
              ),
              if (vm.failed) ...[
                SizedBox(height: m.m),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    l.familyClearPauseError,
                    style: text.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
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
    );
  }
}
