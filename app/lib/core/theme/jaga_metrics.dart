import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Spacing, radii and target sizes (design-system.md section 4).
@immutable
class JagaMetrics extends ThemeExtension<JagaMetrics> {
  const JagaMetrics({
    this.xs = 4,
    this.s = 8,
    this.m = 16,
    this.l = 24,
    this.xl = 32,
    this.xxl = 48,
    this.radiusSmall = 12,
    this.radiusMedium = 20,
    this.radiusLarge = 28,
    this.radiusPill = 999,
    this.minTarget = 56,
    this.primaryButtonHeight = 64,
  });

  static const standard = JagaMetrics();

  final double xs, s, m, l, xl, xxl;
  final double radiusSmall, radiusMedium, radiusLarge, radiusPill;
  final double minTarget, primaryButtonHeight;

  /// Side padding of every screen.
  double get screenPadding => l;

  @override
  JagaMetrics copyWith({
    double? xs,
    double? s,
    double? m,
    double? l,
    double? xl,
    double? xxl,
    double? radiusSmall,
    double? radiusMedium,
    double? radiusLarge,
    double? radiusPill,
    double? minTarget,
    double? primaryButtonHeight,
  }) =>
      JagaMetrics(
        xs: xs ?? this.xs,
        s: s ?? this.s,
        m: m ?? this.m,
        l: l ?? this.l,
        xl: xl ?? this.xl,
        xxl: xxl ?? this.xxl,
        radiusSmall: radiusSmall ?? this.radiusSmall,
        radiusMedium: radiusMedium ?? this.radiusMedium,
        radiusLarge: radiusLarge ?? this.radiusLarge,
        radiusPill: radiusPill ?? this.radiusPill,
        minTarget: minTarget ?? this.minTarget,
        primaryButtonHeight: primaryButtonHeight ?? this.primaryButtonHeight,
      );

  @override
  JagaMetrics lerp(ThemeExtension<JagaMetrics>? other, double t) {
    if (other is! JagaMetrics) return this;
    double v(double a, double b) => lerpDouble(a, b, t)!;
    return JagaMetrics(
      xs: v(xs, other.xs),
      s: v(s, other.s),
      m: v(m, other.m),
      l: v(l, other.l),
      xl: v(xl, other.xl),
      xxl: v(xxl, other.xxl),
      radiusSmall: v(radiusSmall, other.radiusSmall),
      radiusMedium: v(radiusMedium, other.radiusMedium),
      radiusLarge: v(radiusLarge, other.radiusLarge),
      radiusPill: v(radiusPill, other.radiusPill),
      minTarget: v(minTarget, other.minTarget),
      primaryButtonHeight: v(primaryButtonHeight, other.primaryButtonHeight),
    );
  }
}
