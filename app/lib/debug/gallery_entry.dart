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

  /// Family and onboarding screens run capped in the app (`copilotMaxTextScale`).
  double? get maxTextScale => feature == 'family' || feature == 'onboarding'
      ? copilotMaxTextScale
      : null;
  final String state;
  final Widget Function(BuildContext context) build;
}
