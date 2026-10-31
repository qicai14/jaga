import 'package:flutter/material.dart';

const _fallback = ['NotoSansSC', 'NotoSansTamil'];

/// Tamil vowel signs are tall, so every style gets more line height.
double _h(Locale locale, double height) =>
    locale.languageCode == 'ta' ? height + 0.15 : height;

// Colour is never set here: it comes from the ColorScheme / JagaColors.
TextStyle _style(
  Locale locale,
  double size,
  FontWeight weight,
  double height, {
  double? letterSpacing,
  List<FontFeature>? features,
}) =>
    TextStyle(
      fontFamily: 'NotoSans',
      fontFamilyFallback: _fallback,
      fontSize: size,
      fontWeight: weight,
      height: _h(locale, height),
      letterSpacing: letterSpacing,
      fontFeatures: features,
    );

/// The Warning-specific styles (design-system.md section 3).
@immutable
class JagaTextStyles extends ThemeExtension<JagaTextStyles> {
  const JagaTextStyles({
    required this.command,
    required this.linkCode,
  });

  factory JagaTextStyles.of(Locale locale) {
    const tabular = [FontFeature.tabularFigures()];
    return JagaTextStyles(
      command: _style(locale, 52, FontWeight.w800, 1.08),
      linkCode: _style(locale, 48, FontWeight.w800, 1.0,
          letterSpacing: 6.0, features: tabular),
    );
  }

  final TextStyle command;
  final TextStyle linkCode;

  @override
  JagaTextStyles copyWith({
    TextStyle? command,
    TextStyle? linkCode,
  }) =>
      JagaTextStyles(
        command: command ?? this.command,
        linkCode: linkCode ?? this.linkCode,
      );

  @override
  JagaTextStyles lerp(ThemeExtension<JagaTextStyles>? other, double t) {
    if (other is! JagaTextStyles) return this;
    return JagaTextStyles(
      command: TextStyle.lerp(command, other.command, t)!,
      linkCode: TextStyle.lerp(linkCode, other.linkCode, t)!,
    );
  }
}

/// The M3 text theme: nothing below 20sp.
TextTheme jagaTextTheme(Locale locale) {
  final body = _style(locale, 20, FontWeight.w400, 1.4);
  final label = _style(locale, 20, FontWeight.w600, 1.2);
  return TextTheme(
    displaySmall: _style(locale, 36, FontWeight.w700, 1.15),
    headlineMedium: _style(locale, 28, FontWeight.w700, 1.2),
    titleLarge: _style(locale, 24, FontWeight.w600, 1.25),
    titleMedium: _style(locale, 22, FontWeight.w600, 1.25),
    titleSmall: label,
    bodyLarge: _style(locale, 22, FontWeight.w400, 1.4),
    bodyMedium: body,
    bodySmall: body,
    labelLarge: _style(locale, 22, FontWeight.w600, 1.2),
    labelMedium: label,
    labelSmall: label,
  );
}
