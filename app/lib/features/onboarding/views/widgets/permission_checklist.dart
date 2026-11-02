import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../data/services/device_setup_service.dart';
import 'permission_row.dart';

/// The live permissions checklist: onboarding step 4 and the PIN-locked Settings.
/// The owning view model looks again whenever the app resumes.
class PermissionChecklist extends StatelessWidget {
  const PermissionChecklist({
    super.key,
    required this.setup,
    required this.tried,
    required this.onFix,
    this.xiaomi = false,
    this.autostartConfirmed = false,
    this.onConfirmAutostart,
  });

  final Map<SetupItem, bool> setup;
  final Set<SetupItem> tried;
  final void Function(SetupItem) onFix;

  /// Xiaomi phones also list autostart, ticked by hand.
  final bool xiaomi;
  final bool autostartConfirmed;
  final VoidCallback? onConfirmAutostart;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    bool granted(SetupItem i) => setup[i] == true;
    // A refused permission says what to do next once Fix was tried.
    String why(SetupItem i, String title, String normal) =>
        tried.contains(i) && !granted(i)
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
          onFix: () => onFix(SetupItem.phoneCalls),
        ),
        PermissionRow(
          title: l.onboardingPermMicrophone,
          why: why(
            SetupItem.microphone,
            l.onboardingPermMicrophone,
            l.onboardingPermMicrophoneWhy,
          ),
          granted: granted(SetupItem.microphone),
          onFix: () => onFix(SetupItem.microphone),
        ),
        PermissionRow(
          title: l.onboardingPermCallingAccount,
          why: !phoneOk
              ? l.onboardingPermCallingAccountFirst
              : tried.contains(SetupItem.callingAccount) &&
                    !granted(SetupItem.callingAccount)
              ? l.onboardingPermCallingAccountHelp
              : l.onboardingPermCallingAccountWhy,
          granted: granted(SetupItem.callingAccount),
          // Disabled until Phone calls is allowed.
          onFix: phoneOk ? () => onFix(SetupItem.callingAccount) : null,
        ),
        PermissionRow(
          title: l.onboardingPermOverlay,
          why: l.onboardingPermOverlayWhy,
          granted: granted(SetupItem.displayOverApps),
          onFix: () => onFix(SetupItem.displayOverApps),
        ),
        PermissionRow(
          title: l.onboardingPermNotifications,
          why: l.onboardingPermNotificationsWhy,
          granted: granted(SetupItem.notifications),
          onFix: () => onFix(SetupItem.notifications),
        ),
        PermissionRow(
          title: l.onboardingPermFullScreen,
          why: l.onboardingPermFullScreenWhy,
          granted: granted(SetupItem.fullScreenAlerts),
          onFix: () => onFix(SetupItem.fullScreenAlerts),
        ),
        if (xiaomi)
          PermissionRow(
            title: l.onboardingPermAutostart,
            why: l.onboardingPermAutostartWhy,
            granted: autostartConfirmed,
            onFix: () => onFix(SetupItem.autostart),
            onConfirm: onConfirmAutostart,
            fixWhenGranted: true,
          ),
      ],
    );
  }
}
