import 'package:flutter/material.dart';
// contract: na tone/emphasis/state

import '../tokens/v_spacing.dart';

/// Named spacing sizes for layout gaps — maps to [VSpacing] tokens.
enum VGapSize {
  xs(VSpacing.xs),
  sm(VSpacing.sm),
  md(VSpacing.md),
  lg(VSpacing.lg),
  xl(VSpacing.xl),
  xxl(VSpacing.xxl);

  const VGapSize(this.value);
  final double value;
}

/// Vertical or horizontal gap from design-system spacing tokens.
///
/// Prefer named constructors over raw [VGap] with [size].
class VGap extends StatelessWidget {
  const VGap(this.size, {super.key, this.axis = Axis.vertical});

  const VGap.xs({super.key, this.axis = Axis.vertical}) : size = VGapSize.xs;
  const VGap.sm({super.key, this.axis = Axis.vertical}) : size = VGapSize.sm;
  const VGap.md({super.key, this.axis = Axis.vertical}) : size = VGapSize.md;
  const VGap.lg({super.key, this.axis = Axis.vertical}) : size = VGapSize.lg;
  const VGap.xl({super.key, this.axis = Axis.vertical}) : size = VGapSize.xl;
  const VGap.xxl({super.key, this.axis = Axis.vertical}) : size = VGapSize.xxl;

  const VGap.horizontalXs({super.key}) : size = VGapSize.xs, axis = Axis.horizontal;
  const VGap.horizontalSm({super.key}) : size = VGapSize.sm, axis = Axis.horizontal;
  const VGap.horizontalMd({super.key}) : size = VGapSize.md, axis = Axis.horizontal;
  const VGap.horizontalLg({super.key}) : size = VGapSize.lg, axis = Axis.horizontal;

  final VGapSize size;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    final gap = size.value;
    return axis == Axis.vertical
        ? SizedBox(height: gap)
        : SizedBox(width: gap);
  }
}
