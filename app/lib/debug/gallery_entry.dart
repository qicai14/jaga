import 'package:flutter/widgets.dart';

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
}
