import 'package:flutter/material.dart';

import 'package:jaga/core/l10n/gen/app_localizations.dart';
import 'package:jaga/core/theme/theme_context.dart';
import 'package:jaga/core/widgets/screen_frame.dart';
import 'package:jaga/features/warning/view_models/warning_view_model.dart';
import 'package:jaga/features/warning/views/warning_overlay.dart';

/// A bare call screen for the Warning tests, so they test the overlay alone.
/// The real one is InCallScreen.
class CallBackdrop extends StatelessWidget {
  const CallBackdrop({super.key, required this.vm, this.onHangUp});

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
          padding: EdgeInsets.only(
            top: MediaQuery.sizeOf(context).height * 0.3,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                callerNumber,
                style: text.headlineMedium,
                textAlign: TextAlign.center,
              ),
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
