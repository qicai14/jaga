import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../data/services/device_setup_service.dart';
import '../../view_models/onboarding_view_model.dart';
import '../widgets/permission_row.dart';

/// Step 4: a live checklist. The view model looks again whenever the app resumes.
class PermissionsStep extends StatelessWidget {
  const PermissionsStep({super.key, required this.vm});

  final OnboardingViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    bool granted(SetupItem i) => vm.setup[i] == true;
    return Column(
      children: [
        PermissionRow(
          title: l.onboardingPermNotifications,
          why: l.onboardingPermNotificationsWhy,
          granted: granted(SetupItem.notifications),
          onFix: () => vm.fix(SetupItem.notifications),
        ),
        PermissionRow(
          title: l.onboardingPermMicrophone,
          why: l.onboardingPermMicrophoneWhy,
          granted: granted(SetupItem.microphone),
          onFix: () => vm.fix(SetupItem.microphone),
        ),
        PermissionRow(
          title: l.onboardingPermFullScreen,
          why: l.onboardingPermFullScreenWhy,
          granted: granted(SetupItem.fullScreenAlerts),
          onFix: () => vm.fix(SetupItem.fullScreenAlerts),
        ),
        // Waits for #12 (calls): neither ticked nor a problem until then.
        PermissionRow(
          title: l.onboardingPermCallingAccount,
          why: l.onboardingAfterCallSetup,
          granted: false,
          pending: true,
        ),
        if (vm.xiaomi)
          PermissionRow(
            title: l.onboardingPermAutostart,
            why: l.onboardingPermAutostartWhy,
            granted: vm.autostartConfirmed,
            onFix: () => vm.fix(SetupItem.autostart),
            onConfirm: vm.confirmAutostart,
          ),
      ],
    );
  }
}
