import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/pin_pad.dart';
import '../../../../data/repositories/pin_repository.dart';
import '../../view_models/protected_home_view_model.dart';
import 'inline_error.dart';

/// Bottom sheet that asks for the co-pilot lock. Pops true on the right PIN.
class PinGateSheet extends StatefulWidget {
  const PinGateSheet({super.key, required this.vm});

  final ProtectedHomeViewModel vm;

  @override
  State<PinGateSheet> createState() => _PinGateSheetState();
}

class _PinGateSheetState extends State<PinGateSheet> {
  PinResult? _result;

  @override
  void initState() {
    super.initState();
    // Reopened while locked: say so straight away.
    widget.vm.isLocked().then((locked) {
      if (mounted && locked) setState(() => _result = PinResult.locked);
    });
  }

  Future<void> _submit(String pin) async {
    final result = await widget.vm.verifyPin(pin);
    if (!mounted) return;
    if (result == PinResult.ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _result = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = context.metrics;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(m.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                l.settingsPinTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            if (_result != null)
              InlineError(
                _result == PinResult.locked
                    ? l.settingsPinLocked
                    : l.settingsPinWrong,
              ),
            SizedBox(height: m.l),
            IgnorePointer(
              ignoring: _result == PinResult.locked,
              child: PinPad(onCompleted: _submit),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l.commonCancel),
            ),
          ],
        ),
      ),
    );
  }
}
