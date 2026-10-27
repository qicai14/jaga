import 'package:flutter/material.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/widgets/hold_to_confirm_button.dart';
import '../../../core/widgets/screen_frame.dart';
import '../view_models/protected_home_view_model.dart';
import 'widgets/forwarding_body.dart';
import 'widgets/language_list.dart';
import 'widgets/link_code_body.dart';
import 'widgets/pause_token_body.dart';

/// Behind the co-pilot lock: language, forwarding, pause token, link code, reset.
class ProtectedSettingsScreen extends StatelessWidget {
  const ProtectedSettingsScreen({super.key, required this.vm});

  final ProtectedHomeViewModel vm;

  Widget _section(BuildContext context, String title, Widget child) {
    final m = context.metrics;
    return Padding(
      padding: EdgeInsets.only(bottom: m.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          SizedBox(height: m.m),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) => ScreenFrame(
        appBar: AppBar(),
        title: l.settingsTitle,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section(
              context,
              l.onboardingLanguageTitle,
              LanguageList(
                selected: vm.language,
                onSelected: vm.selectLanguage,
              ),
            ),
            _section(
              context,
              l.onboardingForwardTitle,
              ForwardingBody(
                code: vm.registration.forwardingCode,
                onDial: vm.dialForwarding,
                onCheck: vm.checkForwarding,
              ),
            ),
            _section(
              context,
              l.onboardingPauseTitle,
              PauseTokenBody(
                token: vm.registration.pauseToken,
                onShare: vm.shareText,
              ),
            ),
            _section(
              context,
              l.onboardingLinkTitle,
              LinkCodeBody(
                code: vm.registration.linkCode,
                personName: vm.personName,
                joined: vm.family,
                onShare: vm.shareText,
              ),
            ),
            HoldToConfirmButton(
              label: l.settingsReset,
              onConfirmed: () {
                // Leave first: resetting swaps the home screen under this route.
                Navigator.of(context).popUntil((route) => route.isFirst);
                vm.reset();
              },
            ),
          ],
        ),
      ),
    );
  }
}
