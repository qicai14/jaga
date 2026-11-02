import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../data/services/device_setup_service.dart';
import '../../view_models/onboarding_view_model.dart';
import '../widgets/permission_row.dart';

/// Co-pilot step 4: allow alerts, or carry on without them.
class NotificationsStep extends StatelessWidget {
  const NotificationsStep({super.key, required this.vm});

  final OnboardingViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.onboardingNotifBody,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        SizedBox(height: context.metrics.l),
        PermissionRow(
          title: l.onboardingPermNotifications,
          why: l.onboardingPermNotificationsWhy,
          granted: vm.setup[SetupItem.notifications] == true,
          onFix: () => vm.fix(SetupItem.notifications),
        ),
      ],
    );
  }
}
