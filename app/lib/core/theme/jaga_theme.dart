import 'package:flutter/material.dart';

import 'jaga_colors.dart';
import 'jaga_metrics.dart';
import 'jaga_text_styles.dart';

/// The one light theme (design-system.md section 5).
ThemeData buildJagaTheme(Locale locale) {
  const m = JagaMetrics.standard;
  const scheme = jagaColorScheme;
  final text = jagaTextTheme(locale);
  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(m.radiusMedium),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    textTheme: text,
    fontFamily: 'NotoSans',
    fontFamilyFallback: const ['NotoSansSC'],
    scaffoldBackgroundColor: scheme.surface,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
    cardTheme: const CardThemeData(elevation: 0),
    appBarTheme: const AppBarTheme(scrolledUnderElevation: 0),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: Size.fromHeight(m.primaryButtonHeight),
        shape: buttonShape,
        textStyle: text.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: Size(m.minTarget, m.minTarget),
        shape: buttonShape,
        side: BorderSide(color: scheme.outline, width: 2),
        textStyle: text.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: Size(m.minTarget, m.minTarget),
        shape: buttonShape,
        textStyle: text.labelLarge,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainer,
      contentPadding: const EdgeInsets.all(20),
      // A visible resting border: with none, the floated label straddled the
      // top edge of the filled box with nothing for it to sit on.
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(m.radiusSmall),
        borderSide: BorderSide(color: scheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(m.radiusSmall),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    ),
    extensions: [JagaColors.light, m, JagaTextStyles.of(locale)],
  );
}
