import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';

/// The last step of both roles: a big tick under the headline.
class DoneStep extends StatelessWidget {
  const DoneStep({super.key});

  @override
  Widget build(BuildContext context) =>
      Icon(Icons.check_circle, size: 96, color: context.jagaColors.guarded);
}
