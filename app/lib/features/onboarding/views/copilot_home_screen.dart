import 'package:flutter/material.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/widgets/screen_frame.dart';

/// Placeholder until the co-pilot home (#23): says whom the alerts are about.
class CopilotHomeScreen extends StatelessWidget {
  const CopilotHomeScreen({super.key, required this.personName});

  final String personName;

  @override
  Widget build(BuildContext context) => ScreenFrame(
    body: Text(
      AppLocalizations.of(context).onboardingDoneCopilot(personName),
      style: Theme.of(context).textTheme.headlineMedium,
    ),
  );
}
