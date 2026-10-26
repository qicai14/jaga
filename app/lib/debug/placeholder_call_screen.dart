import 'package:flutter/material.dart';

import '../core/l10n/gen/app_localizations.dart';
import '../core/theme/theme_context.dart';
import '../core/widgets/screen_frame.dart';
import '../features/warning/view_models/warning_view_model.dart';
import '../features/warning/views/warning_overlay.dart';

/// Stand-in for the real call screen (#12), so the Caution and Warning can be
/// seen over something. Debug only.
class PlaceholderCallScreen extends StatelessWidget {
  const PlaceholderCallScreen({super.key, required this.vm, this.onHangUp});

  final WarningViewModel vm;
  final VoidCallback? onHangUp;

  static const callerNumber = '+60 3-2610 1599';
  static const timer = '02:14';

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return WarningOverlay(
      vm: vm,
      onHangUp: onHangUp ?? () {},
      child: ScreenFrame(
        body: Padding(
          padding: EdgeInsets.only(top: context.metrics.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(callerNumber, style: text.headlineMedium),
              SizedBox(height: context.metrics.s),
              Text(timer, style: text.bodyLarge),
            ],
          ),
        ),
        bottomAction: Center(
          // Disabled on purpose: the real hang-up arrives with #12.
          child: IconButton.filled(
            onPressed: null,
            iconSize: 32,
            style: IconButton.styleFrom(
              minimumSize: const Size.square(64),
              disabledBackgroundColor: scheme.errorContainer,
              disabledForegroundColor: scheme.onErrorContainer,
            ),
            icon: const Icon(Icons.call_end),
            tooltip: AppLocalizations.of(context).warningHangUp,
          ),
        ),
      ),
    );
  }
}
