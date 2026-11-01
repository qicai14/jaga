import 'package:flutter/material.dart';

/// Semantic colour roles beyond the M3 [ColorScheme] (design-system.md section 2).
@immutable
class JagaColors extends ThemeExtension<JagaColors> {
  const JagaColors({
    required this.guarded,
    required this.onGuarded,
    required this.guardedContainer,
    required this.onGuardedContainer,
    required this.caution,
    required this.onCaution,
    required this.cautionEdge,
    required this.warning,
    required this.onWarning,
    required this.warningNumber,
    required this.genuineContainer,
    required this.onGenuineContainer,
    required this.genuine,
    required this.onGenuine,
    required this.muted,
  });

  static const light = JagaColors(
    guarded: Color(0xFF0B5D4F),
    onGuarded: Color(0xFFFFFFFF),
    guardedContainer: Color(0xFFD5ECE4),
    onGuardedContainer: Color(0xFF04372F),
    caution: Color(0xFFFFC94A),
    onCaution: Color(0xFF2B1D00),
    cautionEdge: Color(0xFF5C1A00),
    warning: Color(0xFF9A0D14),
    onWarning: Color(0xFFFFFFFF),
    warningNumber: Color(0xFFFFE9A8),
    genuineContainer: Color(0xFFDCE8F5),
    onGenuineContainer: Color(0xFF0A2E52),
    genuine: Color(0xFF1D4E89),
    onGenuine: Color(0xFFFFFFFF),
    muted: Color(0xFF6B7472),
  );

  final Color guarded;
  final Color onGuarded;
  final Color guardedContainer;
  final Color onGuardedContainer;
  final Color caution;
  final Color onCaution;
  final Color cautionEdge;
  final Color warning;
  final Color onWarning;
  final Color warningNumber;
  final Color genuineContainer;
  final Color onGenuineContainer;
  final Color genuine;
  final Color onGenuine;
  final Color muted;

  @override
  JagaColors copyWith({
    Color? guarded,
    Color? onGuarded,
    Color? guardedContainer,
    Color? onGuardedContainer,
    Color? caution,
    Color? onCaution,
    Color? cautionEdge,
    Color? warning,
    Color? onWarning,
    Color? warningNumber,
    Color? genuineContainer,
    Color? onGenuineContainer,
    Color? genuine,
    Color? onGenuine,
    Color? muted,
  }) =>
      JagaColors(
        guarded: guarded ?? this.guarded,
        onGuarded: onGuarded ?? this.onGuarded,
        guardedContainer: guardedContainer ?? this.guardedContainer,
        onGuardedContainer: onGuardedContainer ?? this.onGuardedContainer,
        caution: caution ?? this.caution,
        onCaution: onCaution ?? this.onCaution,
        cautionEdge: cautionEdge ?? this.cautionEdge,
        warning: warning ?? this.warning,
        onWarning: onWarning ?? this.onWarning,
        warningNumber: warningNumber ?? this.warningNumber,
        genuineContainer: genuineContainer ?? this.genuineContainer,
        onGenuineContainer: onGenuineContainer ?? this.onGenuineContainer,
        genuine: genuine ?? this.genuine,
        onGenuine: onGenuine ?? this.onGenuine,
        muted: muted ?? this.muted,
      );

  @override
  JagaColors lerp(ThemeExtension<JagaColors>? other, double t) {
    if (other is! JagaColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return JagaColors(
      guarded: l(guarded, other.guarded),
      onGuarded: l(onGuarded, other.onGuarded),
      guardedContainer: l(guardedContainer, other.guardedContainer),
      onGuardedContainer: l(onGuardedContainer, other.onGuardedContainer),
      caution: l(caution, other.caution),
      onCaution: l(onCaution, other.onCaution),
      cautionEdge: l(cautionEdge, other.cautionEdge),
      warning: l(warning, other.warning),
      onWarning: l(onWarning, other.onWarning),
      warningNumber: l(warningNumber, other.warningNumber),
      genuineContainer: l(genuineContainer, other.genuineContainer),
      onGenuineContainer: l(onGenuineContainer, other.onGenuineContainer),
      genuine: l(genuine, other.genuine),
      onGenuine: l(onGenuine, other.onGenuine),
      muted: l(muted, other.muted),
    );
  }
}

/// The hand-built M3 colour scheme (no `fromSeed`, so every pair is known).
const jagaColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF0B5D4F),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFD5ECE4),
  onPrimaryContainer: Color(0xFF04372F),
  secondary: Color(0xFF2E4A45),
  onSecondary: Color(0xFFFFFFFF),
  tertiary: Color(0xFF1D4E89),
  onTertiary: Color(0xFFFFFFFF),
  error: Color(0xFF8C1D18),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFFCE4E1),
  onErrorContainer: Color(0xFF410E0B),
  surface: Color(0xFFFBF8F2),
  onSurface: Color(0xFF1B1F1E),
  onSurfaceVariant: Color(0xFF3B4441),
  surfaceContainer: Color(0xFFEEE9DF),
  surfaceContainerHigh: Color(0xFFE7E2D7),
  outline: Color(0xFF6B7472),
  outlineVariant: Color(0xFFC9C4B8),
);
