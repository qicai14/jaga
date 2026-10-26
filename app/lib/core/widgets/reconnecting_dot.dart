import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../theme/theme_context.dart';

/// Shows that the stream dropped. A static 12dp dot (no animation), in a 48dp area
/// that keeps its size when hidden so nothing shifts. TalkBack hears the label.
class ReconnectingDot extends StatelessWidget {
  const ReconnectingDot({super.key, required this.visible, this.color});

  final bool visible;

  /// Defaults to `JagaColors.muted`; on the Warning pass `onWarning` at 60%.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: visible ? AppLocalizations.of(context).callReconnecting : null,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: 48,
          child: visible
              ? Center(
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color ?? context.jagaColors.muted,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
