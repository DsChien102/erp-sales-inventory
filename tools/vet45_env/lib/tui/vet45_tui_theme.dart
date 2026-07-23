import 'package:nocterm/nocterm.dart';

/// Vet45 Design System palette mirrored for nocterm TUI.
///
/// Source of truth (Flutter): `packages/vet45_design_system` —
/// `VColors` / `VColorScheme.light` / `VColorScheme.dark`.
/// Keep hex values in sync when those tokens change.
///
/// Pure Dart CLI must not depend on the Flutter design_system package.
abstract final class Vet45TuiTheme {
  Vet45TuiTheme._();

  // --- VColors mirror (RGB only; nocterm Color is 0xRRGGBB) ---
  static const Color _primary100 = Color(0xDCEFDE);
  static const Color _primary300 = Color(0x8DCB96);
  static const Color _primary400 = Color(0x5FB36C);
  static const Color _primary500 = Color(0x3B9448);
  static const Color _primary600 = Color(0x2F7A3A);
  static const Color _primary900 = Color(0x163A1C);

  static const Color _neutral0 = Color(0xFFFFFF);
  static const Color _neutral200 = Color(0xE5E8EB);
  static const Color _neutral300 = Color(0xD0D5DA);
  static const Color _neutral500 = Color(0x6B7480);
  static const Color _neutral600 = Color(0x4A535E);
  static const Color _neutral700 = Color(0x2F3640);
  static const Color _neutral900 = Color(0x0E1116);

  static const Color _backgroundLight = Color(0xF6F8F9);
  static const Color _surfaceLight = Color(0xFFFFFF);

  static const Color _success = Color(0x2E9E4B);
  static const Color _warning = Color(0xD98A0B);
  static const Color _danger = Color(0xD14343);

  /// Maps [VColorScheme.dark] → nocterm [TuiThemeData].
  static const TuiThemeData dark = TuiThemeData(
    brightness: Brightness.dark,
    background: _neutral900,
    onBackground: _neutral0,
    surface: _neutral700,
    onSurface: _neutral0,
    primary: _primary400,
    onPrimary: _neutral900,
    secondary: _primary300,
    onSecondary: _neutral900,
    error: _danger,
    onError: _neutral0,
    success: _success,
    onSuccess: _neutral0,
    warning: _warning,
    onWarning: _neutral900,
    outline: _neutral500,
    outlineVariant: _neutral600,
    selectionColor: _primary900,
  );

  /// Maps [VColorScheme.light] → nocterm [TuiThemeData].
  static const TuiThemeData light = TuiThemeData(
    brightness: Brightness.light,
    background: _backgroundLight,
    onBackground: _neutral900,
    surface: _surfaceLight,
    onSurface: _neutral900,
    primary: _primary500,
    onPrimary: _neutral0,
    secondary: _primary600,
    onSecondary: _neutral0,
    error: _danger,
    onError: _neutral0,
    success: _success,
    onSuccess: _neutral0,
    warning: _warning,
    onWarning: _neutral900,
    outline: _neutral300,
    outlineVariant: _neutral200,
    selectionColor: _primary100,
  );
}
