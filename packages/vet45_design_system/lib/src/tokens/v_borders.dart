import 'package:flutter/material.dart';

import '../foundation/v_component_contracts.dart';
import 'v_radius.dart';

/// Shared border stroke widths and factories for design-system controls.
///
/// Colors stay outside this token — pass them from [VColorScheme] / [VColors].
class VBorders {
  VBorders._();

  static const double thin = 1.0;
  static const double medium = 1.3;
  static const double thick = 1.6;

  /// Strong emphasis → [thick]; otherwise [medium].
  static double widthFor(VComponentEmphasis emphasis) =>
      emphasis == VComponentEmphasis.strong ? thick : medium;

  static BorderSide side(Color color, {double width = thin}) =>
      BorderSide(color: color, width: width);

  static Border all(Color color, {double width = thin}) => Border.all(color: color, width: width);

  static OutlineInputBorder outlineInput(
    Color color, {
    double width = thin,
    double radius = VRadius.input,
  }) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(radius),
    borderSide: BorderSide(color: color, width: width),
  );
}
