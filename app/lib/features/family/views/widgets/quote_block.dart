import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';

/// One masked quote of what the caller said, on a quiet card with a left rule.
class QuoteBlock extends StatelessWidget {
  const QuoteBlock({super.key, required this.quote});

  final String quote;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final m = context.metrics;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(m.m),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(m.radiusSmall),
        border: Border(left: BorderSide(color: scheme.outline, width: 4)),
      ),
      child: Text('“$quote”', style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}
