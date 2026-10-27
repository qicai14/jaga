import 'package:flutter/material.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/big_button.dart';
import '../../../core/widgets/screen_frame.dart';
import '../../onboarding/views/widgets/language_list.dart';
import '../view_models/copilot_settings_view_model.dart';

/// The co-pilot's app language, and unlinking from the protected user.
class CopilotSettingsScreen extends StatelessWidget {
  const CopilotSettingsScreen({super.key, required this.vm});

  final CopilotSettingsViewModel vm;

  Future<void> _unlink(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l.familyUnlinkConfirm(vm.person.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.familyUnlinkAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    // Leave first: unlinking swaps the home screen under this route.
    navigator.popUntil((route) => route.isFirst);
    vm.unlink();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = context.metrics;
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) => ScreenFrame(
        appBar: AppBar(),
        title: l.settingsTitle,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                l.onboardingAppLanguageTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            SizedBox(height: m.m),
            LanguageList(selected: vm.language, onSelected: vm.selectLanguage),
            SizedBox(height: m.xl),
            BigButton(
              tone: BigButtonTone.quiet,
              label: l.familyUnlink(vm.person.name),
              onPressed: () => _unlink(context),
            ),
          ],
        ),
      ),
    );
  }
}
