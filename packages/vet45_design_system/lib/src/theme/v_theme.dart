import 'package:flutter/material.dart';
import '../tokens/v_borders.dart';
import '../tokens/v_colors.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_typography.dart';
import 'v_color_scheme.dart';
import 'v_density.dart';

class VTheme {
  VTheme._();

  static ThemeData get lightTheme {
    return lightThemeForDensity(VDensityMode.comfortable);
  }

  static ThemeData lightThemeForDensity(VDensityMode densityMode) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: VColors.neutral25,
      fontFamily: VTypography.fontFamily,
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      colorScheme: const ColorScheme.light(
        primary: VColors.primary500,
        error: VColors.danger,
        surface: VColors.neutral0,
      ),
      extensions: [
        VColorScheme.light,
        VDensity.fromMode(densityMode),
      ],
      appBarTheme: const AppBarTheme(
        backgroundColor: VColors.neutral0,
        foregroundColor: VColors.neutral900,
        elevation: 0,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: VColors.primary500,
        selectionColor: VColors.primary100,
        selectionHandleColor: VColors.primary500,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VColors.neutral0,
        hoverColor: Colors.transparent,
        border: VBorders.outlineInput(VColors.neutral300),
        enabledBorder: VBorders.outlineInput(VColors.neutral300),
        focusedBorder: VBorders.outlineInput(
          VColors.primary500,
          width: VBorders.thick,
        ),
        errorBorder: VBorders.outlineInput(VColors.danger),
        focusedErrorBorder: VBorders.outlineInput(
          VColors.danger,
          width: VBorders.thick,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VColors.primary500,
          foregroundColor: Colors.white,
          elevation: 0,
          overlayColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VRadius.button),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: VColors.neutral0,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VRadius.card),
          side: VBorders.side(VColors.neutral200),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return darkThemeForDensity(VDensityMode.comfortable);
  }

  static ThemeData darkThemeForDensity(VDensityMode densityMode) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: VColors.neutral900,
      fontFamily: VTypography.fontFamily,
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      colorScheme: const ColorScheme.dark(
        primary: VColors.primary400,
        error: VColors.danger,
        surface: VColors.neutral700,
      ),
      extensions: [
        VColorScheme.dark,
        VDensity.fromMode(densityMode),
      ],
      appBarTheme: const AppBarTheme(
        backgroundColor: VColors.neutral700,
        foregroundColor: VColors.neutral0,
        elevation: 0,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: VColors.primary400,
        selectionColor: VColors.primary900,
        selectionHandleColor: VColors.primary400,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VColors.neutral700,
        hoverColor: Colors.transparent,
        border: VBorders.outlineInput(VColors.neutral600),
        enabledBorder: VBorders.outlineInput(VColors.neutral600),
        focusedBorder: VBorders.outlineInput(
          VColors.primary400,
          width: VBorders.thick,
        ),
        errorBorder: VBorders.outlineInput(VColors.danger),
        focusedErrorBorder: VBorders.outlineInput(
          VColors.danger,
          width: VBorders.thick,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VColors.primary400,
          foregroundColor: Colors.white,
          elevation: 0,
          overlayColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VRadius.button),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: VColors.neutral700,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VRadius.card),
          side: VBorders.side(VColors.neutral600),
        ),
      ),
    );
  }
}
