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
    // A refused permission says what to do next once Fix was tried.
    String why(SetupItem i, String title, String normal) =>
        vm.tried.contains(i) && !granted(i)
        ? l.onboardingPermOpenSettingsHelp(title)
        : normal;
    final phoneOk = granted(SetupItem.phoneCalls);
    return Column(
      children: [
        PermissionRow(
          title: l.onboardingPermPhone,
          why: why(
            SetupItem.phoneCalls,
            l.onboardingPermPhone,
            l.onboardingPermPhoneWhy,
          ),
          granted: phoneOk,
          onFix: () => vm.fix(SetupItem.phoneCalls),
        ),
        PermissionRow(
          title: l.onboardingPermMicrophone,
          why: why(
            SetupItem.microphone,
            l.onboardingPermMicrophone,
            l.onboardingPermMicrophoneWhy,
          ),
          granted: granted(SetupItem.microphone),
          onFix: () => vm.fix(SetupItem.microphone),
        ),
        PermissionRow(
          title: l.onboardingPermCallingAccount,
          why: !phoneOk
              ? l.onboardingPermCallingAccountFirst
              : vm.tried.contains(SetupItem.callingAccount) &&
                    !granted(SetupItem.callingAccount)
              ? l.onboardingPermCallingAccountHelp
              : l.onboardingPermCallingAccountWhy,
          granted: granted(SetupItem.callingAccount),
          // Disabled until Phone calls is allowed.
          onFix: phoneOk ? () => vm.fix(SetupItem.callingAccount) : null,
        ),
        PermissionRow(
          title: l.onboardingPermNotifications,
          why: l.onboardingPermNotificationsWhy,
          granted: granted(SetupItem.notifications),
          onFix: () => vm.fix(SetupItem.notifications),
        ),
        PermissionRow(
          title: l.onboardingPermFullScreen,
          why: l.onboardingPermFullScreenWhy,
          granted: granted(SetupItem.fullScreenAlerts),
          onFix: () => vm.fix(SetupItem.fullScreenAlerts),
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
