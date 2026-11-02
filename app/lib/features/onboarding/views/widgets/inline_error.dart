import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';

/// A form error in the error colour, announced to TalkBack when it appears.
class InlineError extends StatelessWidget {
  const InlineError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: context.metrics.m),
      child: Semantics(
        liveRegion: true,
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }
}
