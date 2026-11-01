import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';
import 'choice_card.dart';

/// Each language is named in its own script, so anyone can find theirs.
const _languages = [
  ('ms', 'Bahasa Melayu'),
  ('en', 'English'),
  ('zh', '中文'),
];

class LanguageList extends StatelessWidget {
  const LanguageList({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final m = context.metrics;
    return Column(
      children: [
        for (final (code, name) in _languages)
          Padding(
            padding: EdgeInsets.only(bottom: m.s),
            child: ChoiceCard(
              title: name,
              selected: code == selected,
              onTap: () => onSelected(code),
            ),
          ),
      ],
    );
  }
}
