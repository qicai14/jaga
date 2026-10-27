import 'package:flutter/material.dart';

const _fallback = ['NotoSansSC'];

// Colour is never set here: it comes from the ColorScheme / JagaColors.
TextStyle _style(
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
      height: height,
      letterSpacing: letterSpacing,
      fontFeatures: features,
    );

/// The Warning-specific styles (design-system.md section 3).
@immutable
class JagaTextStyles extends ThemeExtension<JagaTextStyles> {
  const JagaTextStyles({
    required this.command,
    required this.commandEnglish,
    required this.officialNumber,
    required this.linkCode,
  });

  factory JagaTextStyles.of(Locale locale) {
    const tabular = [FontFeature.tabularFigures()];
    return JagaTextStyles(
      command: _style(52, FontWeight.w800, 1.08),
      commandEnglish: _style(30, FontWeight.w700, 1.15),
      officialNumber: _style(40, FontWeight.w800, 1.1,
          letterSpacing: 1.0, features: tabular),
      linkCode: _style(48, FontWeight.w800, 1.0,
          letterSpacing: 6.0, features: tabular),
    );
  }

  final TextStyle command;
  final TextStyle commandEnglish;
  final TextStyle officialNumber;
  final TextStyle linkCode;

  @override
  JagaTextStyles copyWith({
    TextStyle? command,
    TextStyle? commandEnglish,
    TextStyle? officialNumber,
    TextStyle? linkCode,
  }) =>
      JagaTextStyles(
        command: command ?? this.command,
        commandEnglish: commandEnglish ?? this.commandEnglish,
        officialNumber: officialNumber ?? this.officialNumber,
        linkCode: linkCode ?? this.linkCode,
      );

  @override
  JagaTextStyles lerp(ThemeExtension<JagaTextStyles>? other, double t) {
    if (other is! JagaTextStyles) return this;
    return JagaTextStyles(
      command: TextStyle.lerp(command, other.command, t)!,
      commandEnglish: TextStyle.lerp(commandEnglish, other.commandEnglish, t)!,
      officialNumber: TextStyle.lerp(officialNumber, other.officialNumber, t)!,
      linkCode: TextStyle.lerp(linkCode, other.linkCode, t)!,
    );
  }
}

/// The M3 text theme: nothing below 20sp.
TextTheme jagaTextTheme(Locale locale) {
  final body = _style(20, FontWeight.w400, 1.4);
  final label = _style(20, FontWeight.w600, 1.2);
  return TextTheme(
    displaySmall: _style(36, FontWeight.w700, 1.15),
    headlineMedium: _style(28, FontWeight.w700, 1.2),
    titleLarge: _style(24, FontWeight.w600, 1.25),
    titleMedium: _style(22, FontWeight.w600, 1.25),
    titleSmall: label,
    bodyLarge: _style(22, FontWeight.w400, 1.4),
    bodyMedium: body,
    bodySmall: body,
    labelLarge: _style(22, FontWeight.w600, 1.2),
    labelMedium: label,
    labelSmall: label,
  );
}
