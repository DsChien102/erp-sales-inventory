import 'package:flutter/material.dart';
import '../tokens/v_colors.dart';

@immutable
class VColorScheme extends ThemeExtension<VColorScheme> {
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color surfaceBrand;
  final Color borderDefault;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color primary;
  final Color primaryPressed;

  const VColorScheme({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceBrand,
    required this.borderDefault,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.primary,
    required this.primaryPressed,
  });

  // Light theme color scheme mapping
  static final VColorScheme light = VColorScheme(
    background: VColors.background,
    surface: VColors.surface,
    surfaceAlt: VColors.surfaceAlt,
    surfaceBrand: VColors.surfaceBrand,
    borderDefault: VColors.borderDefault,
    borderStrong: VColors.borderStrong,
    textPrimary: VColors.textPrimary,
    textSecondary: VColors.textSecondary,
    textMuted: VColors.textMuted,
    primary: VColors.primary,
    primaryPressed: VColors.primaryPressed,
  );

  // Dark theme color scheme mapping
  static final VColorScheme dark = VColorScheme(
    background: VColors.neutral900,
    surface: VColors.neutral700,
    surfaceAlt: VColors.neutral600,
    surfaceBrand: VColors.primary900,
    borderDefault: VColors.neutral600,
    borderStrong: VColors.neutral500,
    textPrimary: VColors.neutral0,
    textSecondary: VColors.neutral300,
    textMuted: VColors.neutral400,
    primary: VColors.primary400,
    primaryPressed: VColors.primary300,
  );

  @override
  VColorScheme copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? surfaceBrand,
    Color? borderDefault,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? primary,
    Color? primaryPressed,
  }) {
    return VColorScheme(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      surfaceBrand: surfaceBrand ?? this.surfaceBrand,
      borderDefault: borderDefault ?? this.borderDefault,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      primary: primary ?? this.primary,
      primaryPressed: primaryPressed ?? this.primaryPressed,
    );
  }

  @override
  VColorScheme lerp(ThemeExtension<VColorScheme>? other, double t) {
    if (other is! VColorScheme) {
      return this;
    }
    return VColorScheme(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      surfaceBrand: Color.lerp(surfaceBrand, other.surfaceBrand, t)!,
      borderDefault: Color.lerp(borderDefault, other.borderDefault, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryPressed: Color.lerp(primaryPressed, other.primaryPressed, t)!,
    );
  }
}
