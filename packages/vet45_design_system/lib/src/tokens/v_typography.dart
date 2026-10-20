import 'package:flutter/material.dart';

class VTypography {
  VTypography._();

  static const String fontFamily = 'packages/vet45_design_system/Inter';
  static const String monoFontFamily = 'packages/vet45_design_system/JetBrains Mono';

  /// Inter digits are proportional by default ("111" is narrower than "888").
  /// Every sans role turns on `tnum` so amounts and quantities line up in
  /// columns without switching to mono.
  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  // Line heights leave room above the cap height for stacked Vietnamese
  // marks (Ẫ, Ỗ, Ặ): Inter's content box is 1.21em and JetBrains Mono's is
  // 1.32em, and 80% of extra leading goes above the baseline. Roles from
  // headingH3 up need ≥ 1.43 to keep those marks inside the line box.
  // [displayD1] is reserved for numerals and stays tight.
  // test/tokens/v_typography_test.dart locks this.

  // --- Sans (Inter) ---

  /// Numerals only (large single amounts). Too tight for Vietnamese marks.
  static const TextStyle displayD1 = TextStyle(
    fontFamily: fontFamily,
    fontFeatures: _tabular,
    fontSize: 40,
    height: 44 / 40,
    fontWeight: FontWeight.w800,
    letterSpacing: -1,
  );

  static const TextStyle headingH1 = TextStyle(
    fontFamily: fontFamily,
    fontFeatures: _tabular,
    fontSize: 28,
    height: 40 / 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static const TextStyle headingH2 = TextStyle(
    fontFamily: fontFamily,
    fontFeatures: _tabular,
    fontSize: 22,
    height: 32 / 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  static const TextStyle headingH3 = TextStyle(
    fontFamily: fontFamily,
    fontFeatures: _tabular,
    fontSize: 18,
    height: 26 / 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  static const TextStyle headingH4 = TextStyle(
    fontFamily: fontFamily,
    fontFeatures: _tabular,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodyDefault = TextStyle(
    fontFamily: fontFamily,
    fontFeatures: _tabular,
    fontSize: 14,
    height: 22 / 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontFeatures: _tabular,
    fontSize: 13,
    height: 20 / 13,
    fontWeight: FontWeight.w500,
  );

  /// 14px / 20 line — semibold label (form rows, highlight labels).
  static const TextStyle labelDefault = TextStyle(
    fontFamily: fontFamily,
    fontFeatures: _tabular,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
  );

  /// 11px — for status badges, chips, and tight label text.
  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontFeatures: _tabular,
    fontSize: 11,
    height: 16 / 11,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontFeatures: _tabular,
    fontSize: 12,
    height: 18 / 12,
    fontWeight: FontWeight.w600,
  );

  /// 14px / 20 line — semibold action text (buttons, links, CTAs).
  static const TextStyle actionDefault = TextStyle(
    fontFamily: fontFamily,
    fontFeatures: _tabular,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
  );

  // --- Mono (JetBrains Mono) — same size/role as sans counterpart ---

  static const TextStyle displayD1Mono = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 40,
    height: 44 / 40,
    fontWeight: FontWeight.w800,
    letterSpacing: -1,
  );

  static const TextStyle headingH1Mono = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 28,
    height: 40 / 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static const TextStyle headingH2Mono = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 22,
    height: 32 / 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  static const TextStyle headingH3Mono = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 18,
    height: 26 / 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  static const TextStyle headingH4Mono = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodyDefaultMono = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 14,
    height: 22 / 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle bodySmallMono = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 13,
    height: 20 / 13,
    fontWeight: FontWeight.w500,
  );

  /// Mono counterpart of [labelDefault].
  static const TextStyle labelDefaultMono = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
  );

  /// Tabular figures for amounts / SKUs.
  static const TextStyle monoNumeric = TextStyle(
    fontFamily: monoFontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
