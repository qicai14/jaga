import 'dart:async';

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
  bool _locked = false;
  bool _wrong = false;
  bool _busy = false;
  Timer? _unlock;

  @override
  void initState() {
    super.initState();
    // Reopened while locked: say so straight away.
    _syncLock();
  }

  /// Follows the repository: locked until its expiry, then open again.
  Future<void> _syncLock() async {
    final remaining = await widget.vm.lockRemaining();
    if (!mounted) return;
    _unlock?.cancel();
    setState(() {
      _locked = remaining != null;
      _wrong = false;
    });
    if (remaining != null) {
      _unlock = Timer(remaining, () {
        if (mounted) setState(() => _locked = false);
      });
    }
  }

  Future<void> _submit(String pin) async {
    if (_busy) return; // two checks must not overlap
    _busy = true;
    try {
      final result = await widget.vm.verifyPin(pin);
      if (!mounted) return;
      switch (result) {
        case PinResult.ok:
          Navigator.of(context).pop(true);
        case PinResult.wrong:
          setState(() => _wrong = true);
        case PinResult.locked:
          await _syncLock();
      }
    } finally {
      _busy = false;
    }
  }

  @override
  void dispose() {
    _unlock?.cancel();
    super.dispose();
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
            if (_locked || _wrong)
              InlineError(_locked ? l.settingsPinLocked : l.settingsPinWrong),
            SizedBox(height: m.l),
            IgnorePointer(
              ignoring: _locked,
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
