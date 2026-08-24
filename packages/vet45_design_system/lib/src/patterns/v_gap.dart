import 'package:flutter/material.dart';
// contract: na tone/emphasis/state

import '../foundation/v_inspector_scope.dart';
import '../tokens/v_spacing.dart';

/// Vertical or horizontal gap from design-system spacing tokens.
///
/// Prefer named constructors over raw [VGap] with [size].
class VGap extends StatelessWidget {
  const VGap(this.size, {super.key, this.axis = Axis.vertical});

  const VGap.xs({super.key, this.axis = Axis.vertical}) : size = VSpacing.xs;
  const VGap.sm({super.key, this.axis = Axis.vertical}) : size = VSpacing.sm;
  const VGap.md({super.key, this.axis = Axis.vertical}) : size = VSpacing.md;
  const VGap.lg({super.key, this.axis = Axis.vertical}) : size = VSpacing.lg;
  const VGap.xl({super.key, this.axis = Axis.vertical}) : size = VSpacing.xl;
  const VGap.xxl({super.key, this.axis = Axis.vertical}) : size = VSpacing.xxl;

  const VGap.horizontalXs({super.key}) : size = VSpacing.xs, axis = Axis.horizontal;
  const VGap.horizontalSm({super.key}) : size = VSpacing.sm, axis = Axis.horizontal;
  const VGap.horizontalMd({super.key}) : size = VSpacing.md, axis = Axis.horizontal;
  const VGap.horizontalLg({super.key}) : size = VSpacing.lg, axis = Axis.horizontal;

  final double size;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    return vInspectorHide(
      axis == Axis.vertical ? SizedBox(height: size) : SizedBox(width: size),
    );
  }
}
