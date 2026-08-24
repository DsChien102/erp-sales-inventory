import 'package:flutter/material.dart';

import '../foundation/v_context_extensions.dart';
import '../tokens/v_typography.dart';
import '../foundation/v_inspector_scope.dart';

/// Typography scale variants — map 1-1 to [VTypography] public styles.
enum VTextVariant {
  // Sans
  displayD1,
  headingH1,
  headingH2,
  headingH3,
  headingH4,
  bodyDefault,
  bodySmall,
  caption,
  labelSmall,
  // Mono
  displayD1Mono,
  headingH3Mono,
  headingH4Mono,
  bodyDefaultMono,
  bodySmallMono,
  monoNumeric,
}

/// Design-system text primitive. Resolves style from [VTextVariant] + theme color.
class VText extends StatelessWidget {
  const VText(
    this.data, {
    super.key,
    this.variant = VTextVariant.bodyDefault,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.style,
    this.semanticsLabel,
  });

  final String data;
  final VTextVariant variant;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;

  /// Optional merge on top of the resolved variant style.
  final TextStyle? style;
  final String? semanticsLabel;

  TextStyle _baseStyle(VTextVariant variant) {
    return switch (variant) {
      VTextVariant.displayD1 => VTypography.displayD1,
      VTextVariant.headingH1 => VTypography.headingH1,
      VTextVariant.headingH2 => VTypography.headingH2,
      VTextVariant.headingH3 => VTypography.headingH3,
      VTextVariant.headingH4 => VTypography.headingH4,
      VTextVariant.bodyDefault => VTypography.bodyDefault,
      VTextVariant.bodySmall => VTypography.bodySmall,
      VTextVariant.caption => VTypography.caption,
      VTextVariant.labelSmall => VTypography.labelSmall,
      VTextVariant.displayD1Mono => VTypography.displayD1Mono,
      VTextVariant.headingH3Mono => VTypography.headingH3Mono,
      VTextVariant.headingH4Mono => VTypography.headingH4Mono,
      VTextVariant.bodyDefaultMono => VTypography.bodyDefaultMono,
      VTextVariant.bodySmallMono => VTypography.bodySmallMono,
      VTextVariant.monoNumeric => VTypography.monoNumeric,
    };
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final resolved = _baseStyle(variant)
        .copyWith(color: color ?? dynamicColors.textPrimary)
        .merge(style);

    return vInspectorHide(
      Text(
        data,
        style: resolved,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        softWrap: softWrap,
        semanticsLabel: semanticsLabel,
      ),
    );
  }
}
