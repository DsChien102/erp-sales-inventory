import 'package:flutter/material.dart';

class VTypography {
  VTypography._();

  static const String fontFamily = 'packages/vet45_design_system/Inter';
  static const String monoFontFamily = 'packages/vet45_design_system/JetBrains Mono';

  // --- Sans (Inter) ---

  static const TextStyle displayD1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 40,
    height: 44 / 40,
    fontWeight: FontWeight.w800,
    letterSpacing: -1,
  );

  static const TextStyle headingH1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    height: 34 / 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static const TextStyle headingH2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  static const TextStyle headingH3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  static const TextStyle headingH4 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 22 / 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodyDefault = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 22 / 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    height: 20 / 13,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  /// 11px — for status badges, chips, and tight label text.
  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  // --- Mono (JetBrains Mono) — same size/role as sans counterpart ---

  static const TextStyle displayD1Mono = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 40,
    height: 44 / 40,
    fontWeight: FontWeight.w800,
    letterSpacing: -1,
  );

  static const TextStyle headingH3Mono = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );

  static const TextStyle headingH4Mono = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 14,
    height: 22 / 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodyDefaultMono = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 14,
    height: 22 / 14,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodySmallMono = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 13,
    height: 20 / 13,
    fontWeight: FontWeight.w400,
  );

  /// Tabular figures for amounts / SKUs.
  static const TextStyle monoNumeric = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
