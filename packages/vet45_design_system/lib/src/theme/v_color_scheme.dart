import 'package:flutter/material.dart';

import '../foundation/v_component_contracts.dart';
import '../tokens/v_colors.dart';

@immutable
class VColorScheme extends ThemeExtension<VColorScheme> {
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color surfaceBrand;
  final Color borderDefault;
  final Color borderStrong;
  final Color borderBrand;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textBrand;
  final Color textInverse;
  final Color primary;
  final Color primaryHover;
  final Color primaryPressed;
  final Color primaryFocus;
  final Color primaryDisabled;
  final Color surfaceHover;
  final Color surfacePressed;
  final Color focusRing;
  final Color disabledBg;
  final Color disabledBorder;
  final Color disabledFg;

  /// Inverted surface for toast / snackbar chrome (not text).
  final Color toastSurface;

  // Semantic and status colors
  final Color success;
  final Color successBg;
  final Color successBgPressed;
  final Color warning;
  final Color warningHover;
  final Color warningPressed;
  final Color warningBg;
  final Color warningBgPressed;
  final Color danger;
  final Color dangerHover;
  final Color dangerPressed;
  final Color dangerBg;
  final Color dangerBgPressed;
  final Color info;
  final Color infoHover;
  final Color infoPressed;
  final Color infoBg;
  final Color infoBgPressed;

  const VColorScheme({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceBrand,
    required this.borderDefault,
    required this.borderStrong,
    required this.borderBrand,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textBrand,
    required this.textInverse,
    required this.primary,
    required this.primaryHover,
    required this.primaryPressed,
    required this.primaryFocus,
    required this.primaryDisabled,
    required this.surfaceHover,
    required this.surfacePressed,
    required this.focusRing,
    required this.disabledBg,
    required this.disabledBorder,
    required this.disabledFg,
    required this.toastSurface,
    required this.success,
    required this.successBg,
    required this.successBgPressed,
    required this.warning,
    required this.warningHover,
    required this.warningPressed,
    required this.warningBg,
    required this.warningBgPressed,
    required this.danger,
    required this.dangerHover,
    required this.dangerPressed,
    required this.dangerBg,
    required this.dangerBgPressed,
    required this.info,
    required this.infoHover,
    required this.infoPressed,
    required this.infoBg,
    required this.infoBgPressed,
  });

  // Light theme color scheme mapping
  static final VColorScheme light = VColorScheme(
    background: VColors.neutral100,
    surface: VColors.neutral0,
    surfaceAlt: VColors.neutral100,
    surfaceBrand: VColors.primary50,
    borderDefault: VColors.neutral200,
    borderStrong: VColors.neutral300,
    borderBrand: VColors.primary200,
    textPrimary: VColors.neutral900,
    textSecondary: VColors.neutral500,
    textMuted: VColors.neutral400,
    textBrand: VColors.primary700,
    textInverse: VColors.neutral0,
    primary: VColors.primary500,
    primaryHover: VColors.primary600,
    primaryPressed: VColors.primary700,
    primaryFocus: VColors.primary500,
    primaryDisabled: VColors.neutral200,
    surfaceHover: VColors.neutral50,
    surfacePressed: VColors.neutral100,
    focusRing: VColors.primary200,
    disabledBg: VColors.neutral100,
    disabledBorder: VColors.neutral200,
    disabledFg: VColors.neutral400,
    toastSurface: VColors.neutral900,
    success: VColors.primary500,
    successBg: VColors.primary50,
    successBgPressed: VColors.primary100,
    warning: VColors.yellow500,
    warningHover: VColors.yellow600,
    warningPressed: VColors.yellow700,
    warningBg: VColors.yellow50,
    warningBgPressed: VColors.yellow100,
    danger: VColors.red500,
    dangerHover: VColors.red600,
    dangerPressed: VColors.red700,
    dangerBg: VColors.red50,
    dangerBgPressed: VColors.red100,
    info: VColors.blue500,
    infoHover: VColors.blue600,
    infoPressed: VColors.blue700,
    infoBg: VColors.blue50,
    infoBgPressed: VColors.blue100,
  );

  // Dark theme color scheme mapping
  static final VColorScheme dark = VColorScheme(
    background: VColors.neutral900,
    surface: VColors.neutral700,
    surfaceAlt: VColors.neutral600,
    surfaceBrand: VColors.primary900,
    borderDefault: VColors.neutral600,
    borderStrong: VColors.neutral500,
    borderBrand: VColors.primary700,
    textPrimary: VColors.neutral0,
    textSecondary: VColors.neutral300,
    textMuted: VColors.neutral400,
    textBrand: VColors.primary300,
    textInverse: VColors.primary900,
    primary: VColors.primary400,
    primaryHover: VColors.primary300,
    primaryPressed: VColors.primary300,
    primaryFocus: VColors.primary400,
    primaryDisabled: VColors.primary800,
    surfaceHover: VColors.neutral600,
    surfacePressed: VColors.neutral500,
    focusRing: VColors.primary700,
    disabledBg: VColors.neutral700,
    disabledBorder: VColors.neutral600,
    disabledFg: VColors.neutral500,
    toastSurface: VColors.neutral0,
    success: VColors.primary500,
    successBg: VColors.neutral700,
    successBgPressed: VColors.neutral600,
    warning: VColors.yellow500,
    warningHover: VColors.yellow400,
    warningPressed: VColors.yellow300,
    warningBg: VColors.neutral700,
    warningBgPressed: VColors.neutral600,
    danger: VColors.red500,
    dangerHover: VColors.red400,
    dangerPressed: VColors.red300,
    dangerBg: VColors.neutral700,
    dangerBgPressed: VColors.neutral600,
    info: VColors.blue500,
    infoHover: VColors.blue400,
    infoPressed: VColors.blue300,
    infoBg: VColors.neutral700,
    infoBgPressed: VColors.neutral600,
  );

  @override
  VColorScheme copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? surfaceBrand,
    Color? borderDefault,
    Color? borderStrong,
    Color? borderBrand,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textBrand,
    Color? textInverse,
    Color? primary,
    Color? primaryHover,
    Color? primaryPressed,
    Color? primaryFocus,
    Color? primaryDisabled,
    Color? surfaceHover,
    Color? surfacePressed,
    Color? focusRing,
    Color? disabledBg,
    Color? disabledBorder,
    Color? disabledFg,
    Color? toastSurface,
    Color? success,
    Color? successBg,
    Color? successBgPressed,
    Color? warning,
    Color? warningHover,
    Color? warningPressed,
    Color? warningBg,
    Color? warningBgPressed,
    Color? danger,
    Color? dangerHover,
    Color? dangerPressed,
    Color? dangerBg,
    Color? dangerBgPressed,
    Color? info,
    Color? infoHover,
    Color? infoPressed,
    Color? infoBg,
    Color? infoBgPressed,
  }) {
    return VColorScheme(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      surfaceBrand: surfaceBrand ?? this.surfaceBrand,
      borderDefault: borderDefault ?? this.borderDefault,
      borderStrong: borderStrong ?? this.borderStrong,
      borderBrand: borderBrand ?? this.borderBrand,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textBrand: textBrand ?? this.textBrand,
      textInverse: textInverse ?? this.textInverse,
      primary: primary ?? this.primary,
      primaryHover: primaryHover ?? this.primaryHover,
      primaryPressed: primaryPressed ?? this.primaryPressed,
      primaryFocus: primaryFocus ?? this.primaryFocus,
      primaryDisabled: primaryDisabled ?? this.primaryDisabled,
      surfaceHover: surfaceHover ?? this.surfaceHover,
      surfacePressed: surfacePressed ?? this.surfacePressed,
      focusRing: focusRing ?? this.focusRing,
      disabledBg: disabledBg ?? this.disabledBg,
      disabledBorder: disabledBorder ?? this.disabledBorder,
      disabledFg: disabledFg ?? this.disabledFg,
      toastSurface: toastSurface ?? this.toastSurface,
      success: success ?? this.success,
      successBg: successBg ?? this.successBg,
      successBgPressed: successBgPressed ?? this.successBgPressed,
      warning: warning ?? this.warning,
      warningHover: warningHover ?? this.warningHover,
      warningPressed: warningPressed ?? this.warningPressed,
      warningBg: warningBg ?? this.warningBg,
      warningBgPressed: warningBgPressed ?? this.warningBgPressed,
      danger: danger ?? this.danger,
      dangerHover: dangerHover ?? this.dangerHover,
      dangerPressed: dangerPressed ?? this.dangerPressed,
      dangerBg: dangerBg ?? this.dangerBg,
      dangerBgPressed: dangerBgPressed ?? this.dangerBgPressed,
      info: info ?? this.info,
      infoHover: infoHover ?? this.infoHover,
      infoPressed: infoPressed ?? this.infoPressed,
      infoBg: infoBg ?? this.infoBg,
      infoBgPressed: infoBgPressed ?? this.infoBgPressed,
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
      borderBrand: Color.lerp(borderBrand, other.borderBrand, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textBrand: Color.lerp(textBrand, other.textBrand, t)!,
      textInverse: Color.lerp(textInverse, other.textInverse, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryHover: Color.lerp(primaryHover, other.primaryHover, t)!,
      primaryPressed: Color.lerp(primaryPressed, other.primaryPressed, t)!,
      primaryFocus: Color.lerp(primaryFocus, other.primaryFocus, t)!,
      primaryDisabled: Color.lerp(primaryDisabled, other.primaryDisabled, t)!,
      surfaceHover: Color.lerp(surfaceHover, other.surfaceHover, t)!,
      surfacePressed: Color.lerp(surfacePressed, other.surfacePressed, t)!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
      disabledBg: Color.lerp(disabledBg, other.disabledBg, t)!,
      disabledBorder: Color.lerp(disabledBorder, other.disabledBorder, t)!,
      disabledFg: Color.lerp(disabledFg, other.disabledFg, t)!,
      toastSurface: Color.lerp(toastSurface, other.toastSurface, t)!,
      success: Color.lerp(success, other.success, t)!,
      successBg: Color.lerp(successBg, other.successBg, t)!,
      successBgPressed: Color.lerp(successBgPressed, other.successBgPressed, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningHover: Color.lerp(warningHover, other.warningHover, t)!,
      warningPressed: Color.lerp(warningPressed, other.warningPressed, t)!,
      warningBg: Color.lerp(warningBg, other.warningBg, t)!,
      warningBgPressed: Color.lerp(warningBgPressed, other.warningBgPressed, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerHover: Color.lerp(dangerHover, other.dangerHover, t)!,
      dangerPressed: Color.lerp(dangerPressed, other.dangerPressed, t)!,
      dangerBg: Color.lerp(dangerBg, other.dangerBg, t)!,
      dangerBgPressed: Color.lerp(dangerBgPressed, other.dangerBgPressed, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoHover: Color.lerp(infoHover, other.infoHover, t)!,
      infoPressed: Color.lerp(infoPressed, other.infoPressed, t)!,
      infoBg: Color.lerp(infoBg, other.infoBg, t)!,
      infoBgPressed: Color.lerp(infoBgPressed, other.infoBgPressed, t)!,
    );
  }

  /// Tinted surface for [tone] (shade 50 in light theme).
  Color? backgroundForTone(VComponentTone? tone) {
    if (tone == null) return null;
    return switch (tone) {
      VComponentTone.primary => surfaceBrand,
      VComponentTone.success => successBg,
      VComponentTone.warning => warningBg,
      VComponentTone.danger => dangerBg,
      VComponentTone.info => infoBg,
      VComponentTone.neutral => surfaceAlt,
    };
  }

  /// Border for [tone] on tinted surfaces; solid, no alpha.
  Color? borderForTone(VComponentTone? tone) {
    if (tone == null) return null;
    return switch (tone) {
      VComponentTone.neutral => borderStrong,
      VComponentTone.primary => borderBrand,
      VComponentTone.success => success,
      VComponentTone.warning => warning,
      VComponentTone.danger => danger,
      VComponentTone.info => info,
    };
  }

  /// Semantic foreground for [tone]. Null tone → null (caller picks fallback).
  Color? foregroundForTone(VComponentTone? tone) {
    if (tone == null) return null;
    return switch (tone) {
      VComponentTone.primary => textBrand,
      VComponentTone.success => success,
      VComponentTone.warning => warning,
      VComponentTone.danger => danger,
      VComponentTone.info => info,
      VComponentTone.neutral => textPrimary,
    };
  }
}
