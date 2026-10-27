import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/theme_context.dart';
import '../../view_models/onboarding_view_model.dart';
import '../widgets/inline_error.dart';

const _maxNameLength = 30;

/// Step 3: what the family calls her, and the region (information only).
class AboutStep extends StatefulWidget {
  const AboutStep({super.key, required this.vm});

  final OnboardingViewModel vm;

  @override
  State<AboutStep> createState() => _AboutStepState();
}

class _AboutStepState extends State<AboutStep> {
  late final _name = TextEditingController(text: widget.vm.name);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = context.metrics;
    final vm = widget.vm;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _name,
          enabled: !vm.aboutLocked,
          maxLength: _maxNameLength,
          textCapitalization: TextCapitalization.words,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(labelText: l.onboardingNameLabel),
          onChanged: vm.setName,
        ),
        SizedBox(height: m.m),
        Text(
          l.onboardingRegionInfo,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        if (vm.networkError) InlineError(l.onboardingNetworkError),
      ],
    );
  }
}
