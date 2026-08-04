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
  final Color textBrand;
  final Color primary;
  final Color primaryHover;
  final Color primaryPressed;
  final Color primaryFocus;
  final Color surfaceHover;
  final Color surfacePressed;
  final Color focusRing;
  final Color disabledBg;
  final Color disabledBorder;
  final Color disabledFg;

  // Semantic and status colors
  final Color success;
  final Color successBg;
  final Color warning;
  final Color warningBg;
  final Color danger;
  final Color dangerBg;
  final Color info;
  final Color infoBg;

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
    required this.textBrand,
    required this.primary,
    required this.primaryHover,
    required this.primaryPressed,
    required this.primaryFocus,
    required this.surfaceHover,
    required this.surfacePressed,
    required this.focusRing,
    required this.disabledBg,
    required this.disabledBorder,
    required this.disabledFg,
    required this.success,
    required this.successBg,
    required this.warning,
    required this.warningBg,
    required this.danger,
    required this.dangerBg,
    required this.info,
    required this.infoBg,
  });

  // Light theme color scheme mapping
  static final VColorScheme light = VColorScheme(
    background: VColors.neutral25,
    surface: VColors.neutral0,
    surfaceAlt: VColors.neutral100,
    surfaceBrand: VColors.primary50,
    borderDefault: VColors.neutral200,
    borderStrong: VColors.neutral300,
    textPrimary: VColors.neutral900,
    textSecondary: VColors.neutral500,
    textMuted: VColors.neutral400,
    textBrand: VColors.primary700,
    primary: VColors.primary500,
    primaryHover: VColors.primary600,
    primaryPressed: VColors.primary600,
    primaryFocus: VColors.primary500,
    surfaceHover: VColors.neutral50,
    surfacePressed: VColors.neutral100,
    focusRing: VColors.primary200,
    disabledBg: VColors.neutral100,
    disabledBorder: VColors.neutral200,
    disabledFg: VColors.neutral400,
    success: VColors.success,
    successBg: VColors.successBg,
    warning: VColors.warning,
    warningBg: VColors.warningBg,
    danger: VColors.danger,
    dangerBg: VColors.dangerBg,
    info: VColors.info,
    infoBg: VColors.infoBg,
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
    textBrand: VColors.primary300,
    primary: VColors.primary400,
    primaryHover: VColors.primary300,
    primaryPressed: VColors.primary300,
    primaryFocus: VColors.primary400,
    surfaceHover: VColors.neutral600,
    surfacePressed: VColors.neutral500,
    focusRing: VColors.primary700,
    disabledBg: VColors.neutral700,
    disabledBorder: VColors.neutral600,
    disabledFg: VColors.neutral500,
    success: VColors.success,
    successBg: VColors.neutral700,
    warning: VColors.warning,
    warningBg: VColors.neutral700,
    danger: VColors.danger,
    dangerBg: VColors.neutral700,
    info: VColors.info,
    infoBg: VColors.neutral700,
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
    Color? textBrand,
    Color? primary,
    Color? primaryHover,
    Color? primaryPressed,
    Color? primaryFocus,
    Color? surfaceHover,
    Color? surfacePressed,
    Color? focusRing,
    Color? disabledBg,
    Color? disabledBorder,
    Color? disabledFg,
    Color? success,
    Color? successBg,
    Color? warning,
    Color? warningBg,
    Color? danger,
    Color? dangerBg,
    Color? info,
    Color? infoBg,
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
      textBrand: textBrand ?? this.textBrand,
      primary: primary ?? this.primary,
      primaryHover: primaryHover ?? this.primaryHover,
      primaryPressed: primaryPressed ?? this.primaryPressed,
      primaryFocus: primaryFocus ?? this.primaryFocus,
      surfaceHover: surfaceHover ?? this.surfaceHover,
      surfacePressed: surfacePressed ?? this.surfacePressed,
      focusRing: focusRing ?? this.focusRing,
      disabledBg: disabledBg ?? this.disabledBg,
      disabledBorder: disabledBorder ?? this.disabledBorder,
      disabledFg: disabledFg ?? this.disabledFg,
      success: success ?? this.success,
      successBg: successBg ?? this.successBg,
      warning: warning ?? this.warning,
      warningBg: warningBg ?? this.warningBg,
      danger: danger ?? this.danger,
      dangerBg: dangerBg ?? this.dangerBg,
      info: info ?? this.info,
      infoBg: infoBg ?? this.infoBg,
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
      textBrand: Color.lerp(textBrand, other.textBrand, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryHover: Color.lerp(primaryHover, other.primaryHover, t)!,
      primaryPressed: Color.lerp(primaryPressed, other.primaryPressed, t)!,
      primaryFocus: Color.lerp(primaryFocus, other.primaryFocus, t)!,
      surfaceHover: Color.lerp(surfaceHover, other.surfaceHover, t)!,
      surfacePressed: Color.lerp(surfacePressed, other.surfacePressed, t)!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
      disabledBg: Color.lerp(disabledBg, other.disabledBg, t)!,
      disabledBorder: Color.lerp(disabledBorder, other.disabledBorder, t)!,
      disabledFg: Color.lerp(disabledFg, other.disabledFg, t)!,
      success: Color.lerp(success, other.success, t)!,
      successBg: Color.lerp(successBg, other.successBg, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningBg: Color.lerp(warningBg, other.warningBg, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerBg: Color.lerp(dangerBg, other.dangerBg, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoBg: Color.lerp(infoBg, other.infoBg, t)!,
    );
  }
}
