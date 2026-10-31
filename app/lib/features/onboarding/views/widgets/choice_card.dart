import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';

/// One large choice: a role, or a language. Selected = 3dp teal border and a tick.
class ChoiceCard extends StatelessWidget {
  const ChoiceCard({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.body,
  });

  final String title;
  final String? body;
  final bool selected;

  /// Null makes the card read-only.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final m = context.metrics;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: onTap != null,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: scheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(m.radiusLarge),
          side: BorderSide(
            color: selected ? scheme.primary : Colors.transparent,
            width: 3,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(m.radiusLarge),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 96),
            child: Padding(
              padding: EdgeInsets.all(m.m),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: text.titleLarge),
                        if (body != null) Text(body!, style: text.bodyMedium),
                      ],
                    ),
                  ),
                  if (selected)
                    Padding(
                      padding: EdgeInsets.only(left: m.s),
                      child: Icon(
                        Icons.check_circle,
                        size: 32,
                        color: context.jagaColors.guarded,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
