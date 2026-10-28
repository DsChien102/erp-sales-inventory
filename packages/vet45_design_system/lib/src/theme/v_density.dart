import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';

enum VDensityMode { compact, comfortable }

/// Control sizes and field padding.
///
/// Density follows how the screen is touched, never how wide it is. Phones and
/// touch devices are finger-driven (often standing, one hand, bright
/// light), so they run [comfortable]; do not derive the mode from a
/// breakpoint. [compact] is for pointer-driven windows (web trên máy tính / desktop) only.
/// Controls below [VSpacing.minTouchTarget] still extend their hit area to it.
@immutable
class VDensity extends ThemeExtension<VDensity> {
  final VDensityMode mode;
  final double controlHeightSmall;
  final double controlHeightMedium;
  final double controlHeightLarge;
  final double fieldVerticalPadding;
  final double fieldHorizontalPadding;

  const VDensity({
    required this.mode,
    required this.controlHeightSmall,
    required this.controlHeightMedium,
    required this.controlHeightLarge,
    required this.fieldVerticalPadding,
    required this.fieldHorizontalPadding,
  });

  static const VDensity comfortable = VDensity(
    mode: VDensityMode.comfortable,
    controlHeightSmall: 36,
    controlHeightMedium: 44,
    controlHeightLarge: 52,
    fieldVerticalPadding: 12,
    fieldHorizontalPadding: 16,
  );

  static const VDensity compact = VDensity(
    mode: VDensityMode.compact,
    controlHeightSmall: 32,
    controlHeightMedium: 40,
    controlHeightLarge: 48,
    fieldVerticalPadding: 10,
    fieldHorizontalPadding: 14,
  );

  static VDensity fromMode(VDensityMode mode) {
    return mode == VDensityMode.compact ? compact : comfortable;
  }

  @override
  VDensity copyWith({
    VDensityMode? mode,
    double? controlHeightSmall,
    double? controlHeightMedium,
    double? controlHeightLarge,
    double? fieldVerticalPadding,
    double? fieldHorizontalPadding,
  }) {
    return VDensity(
      mode: mode ?? this.mode,
      controlHeightSmall: controlHeightSmall ?? this.controlHeightSmall,
      controlHeightMedium: controlHeightMedium ?? this.controlHeightMedium,
      controlHeightLarge: controlHeightLarge ?? this.controlHeightLarge,
      fieldVerticalPadding: fieldVerticalPadding ?? this.fieldVerticalPadding,
      fieldHorizontalPadding: fieldHorizontalPadding ?? this.fieldHorizontalPadding,
    );
  }

  @override
  VDensity lerp(ThemeExtension<VDensity>? other, double t) {
    if (other is! VDensity) {
      return this;
    }
    return VDensity(
      mode: t < 0.5 ? mode : other.mode,
      controlHeightSmall: lerpDouble(controlHeightSmall, other.controlHeightSmall, t)!,
      controlHeightMedium: lerpDouble(controlHeightMedium, other.controlHeightMedium, t)!,
      controlHeightLarge: lerpDouble(controlHeightLarge, other.controlHeightLarge, t)!,
      fieldVerticalPadding: lerpDouble(fieldVerticalPadding, other.fieldVerticalPadding, t)!,
      fieldHorizontalPadding: lerpDouble(fieldHorizontalPadding, other.fieldHorizontalPadding, t)!,
    );
  }
}
