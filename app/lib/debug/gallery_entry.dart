import 'package:flutter/widgets.dart';

import '../core/theme/text_scale.dart';

/// One screen state in the debug gallery, e.g. feature "warning", state "high".
class GalleryEntry {
  const GalleryEntry({
    required this.feature,
    required this.state,
    required this.build,
  });

  final String feature;

  final String state;
  final Widget Function(BuildContext context) build;

  /// Family and onboarding screens run capped in the app (`copilotMaxTextScale`),
  /// except the protected phone's own status and settings screens.
  double? get maxTextScale =>
      feature == 'family' ||
          (feature == 'onboarding' &&
              !state.startsWith('status') &&
              state != 'settings')
      ? copilotMaxTextScale
      : null;
}
