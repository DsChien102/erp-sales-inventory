import 'package:flutter/material.dart';

import '../tokens/v_spacing.dart';

/// Outer edge inset — matches [VTextField.padding] / [VTextField.densePadding]
/// horizontal.
const double kVTextFieldAffixOuter = VSpacing.space3;
const double kVTextFieldAffixOuterDense = VSpacing.space2;

/// Gap between affix icon and input text.
const double kVTextFieldAffixInner = VSpacing.space1;
const double kVTextFieldAffixInnerDense = VSpacing.space0;

/// Shared affix inset for [VTextField] / [VTextArea] prefix & suffix.
///
/// [outerInset] = field edge → icon; [innerInset] = icon → text.
Widget? wrapVTextFieldAffix(
  Widget? child, {
  required double outerInset,
  required double innerInset,
  required bool isLeading,
}) {
  if (child == null) return null;
  return Padding(
    padding: EdgeInsets.only(
      left: isLeading ? outerInset : innerInset,
      right: isLeading ? innerInset : outerInset,
    ),
    child: Align(
      widthFactor: 1,
      heightFactor: 1,
      child: child,
    ),
  );
}

/// Horizontal [contentPadding] with start/end zeroed when the matching affix
/// is present (affix owns that inset).
EdgeInsets vTextFieldContentPadding({
  required EdgeInsets base,
  required bool hasPrefix,
  required bool hasSuffix,
}) {
  return base.copyWith(
    left: hasPrefix ? 0 : base.left,
    right: hasSuffix ? 0 : base.right,
  );
}
