import 'package:flutter/material.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/screen_frame.dart';
import '../view_models/protected_home_view_model.dart';
import 'protected_settings_screen.dart';
import 'widgets/pin_gate_sheet.dart';

/// The protected user's home: Jaga is protecting her, and who is watching over
/// her. Settings sit behind a long press and the co-pilot lock; nothing here
/// hints at that.
class ProtectedHomeScreen extends StatelessWidget {
  const ProtectedHomeScreen({super.key, required this.vm});

  final ProtectedHomeViewModel vm;

  Future<void> _openSettings(BuildContext context) async {
    final unlocked = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => PinGateSheet(vm: vm),
    );
    if (unlocked == true && context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ProtectedSettingsScreen(vm: vm),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = context.metrics;
    final text = Theme.of(context).textTheme;
    final c = context.jagaColors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => _openSettings(context),
      child: ListenableBuilder(
        listenable: vm,
        builder: (context, _) => ScreenFrame(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (vm.needsAttention)
                // Amber, like the Caution: not red, which means Warning.
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: c.caution,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.priority_high,
                    size: 64,
                    color: c.onCaution,
                  ),
                )
              else
                Icon(Icons.check_circle, size: 96, color: c.guarded),
              SizedBox(height: m.l),
              Semantics(
                liveRegion: true,
                child: Text(
                  vm.needsAttention ? l.statusNeedsFamily : l.statusProtected,
                  style: text.displaySmall,
                ),
              ),
              SizedBox(height: m.xl),
              Text(l.statusFamilyLabel, style: text.bodyMedium),
              Text(
                vm.family.isEmpty ? l.statusFamilyNone : vm.family.join(', '),
                style: text.titleLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
