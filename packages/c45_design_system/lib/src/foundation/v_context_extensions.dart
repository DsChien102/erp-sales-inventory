import 'package:flutter/material.dart';
import '../theme/v_color_scheme.dart';
import '../theme/v_density.dart';
import '../tokens/v_breakpoints.dart';

extension VThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);

  ColorScheme get colorScheme => theme.colorScheme;

  TextTheme get textTheme => theme.textTheme;

  // Convenient access to our custom dynamic VColorScheme
  VColorScheme get vColors => theme.extension<VColorScheme>() ?? VColorScheme.light;

  // Runtime density contract for controls and fields.
  VDensity get vDensity => theme.extension<VDensity>() ?? VDensity.comfortable;

  /// Current layout breakpoint from [MediaQuery] width.
  VBreakpoint get vBreakpoint => VBreakpoints.of(this);
}
