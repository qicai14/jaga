import 'package:flutter/material.dart';

import 'jaga_colors.dart';
import 'jaga_metrics.dart';
import 'jaga_text_styles.dart';

extension JagaThemeContext on BuildContext {
  JagaColors get jagaColors => Theme.of(this).extension<JagaColors>()!;
  JagaMetrics get metrics => Theme.of(this).extension<JagaMetrics>()!;
  JagaTextStyles get jagaText => Theme.of(this).extension<JagaTextStyles>()!;
}
