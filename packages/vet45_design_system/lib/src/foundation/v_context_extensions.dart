import 'package:flutter/material.dart';
import '../theme/v_color_scheme.dart';

extension VThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);

  ColorScheme get colorScheme => theme.colorScheme;

  TextTheme get textTheme => theme.textTheme;

  // Convenient access to our custom dynamic VColorScheme
  VColorScheme get vColors => theme.extension<VColorScheme>() ?? VColorScheme.light;
}
