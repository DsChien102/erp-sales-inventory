import 'package:flutter/material.dart';
import '../tokens/v_colors.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_typography.dart';
import 'v_color_scheme.dart';

class VTheme {
  VTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: VColors.background,
      fontFamily: VTypography.fontFamily,
      colorScheme: const ColorScheme.light(
        primary: VColors.primary500,
        error: VColors.danger,
        surface: VColors.surface,
      ),
      extensions: [
        VColorScheme.light,
      ],
      appBarTheme: const AppBarTheme(
        backgroundColor: VColors.surface,
        foregroundColor: VColors.textPrimary,
        elevation: 0,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: VColors.primary500,
        selectionColor: VColors.primary100,
        selectionHandleColor: VColors.primary500,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VRadius.input),
          borderSide: const BorderSide(color: VColors.borderStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VRadius.input),
          borderSide: const BorderSide(color: VColors.borderStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VRadius.input),
          borderSide: const BorderSide(color: VColors.primary500, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VRadius.input),
          borderSide: const BorderSide(color: VColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VRadius.input),
          borderSide: const BorderSide(color: VColors.danger, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VColors.primary500,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VRadius.button),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: VColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VRadius.card),
          side: const BorderSide(color: VColors.borderDefault),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: VColors.neutral900,
      fontFamily: VTypography.fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: VColors.primary400,
        error: VColors.danger,
        surface: VColors.neutral700,
      ),
      extensions: [
        VColorScheme.dark,
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VRadius.input),
          borderSide: const BorderSide(color: VColors.neutral600),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VRadius.input),
          borderSide: const BorderSide(color: VColors.neutral600),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VRadius.input),
          borderSide: const BorderSide(color: VColors.primary400, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VRadius.input),
          borderSide: const BorderSide(color: VColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(VRadius.input),
          borderSide: const BorderSide(color: VColors.danger, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VColors.primary400,
          foregroundColor: Colors.white,
          elevation: 0,
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
          side: const BorderSide(color: VColors.neutral600),
        ),
      ),
    );
  }
}
