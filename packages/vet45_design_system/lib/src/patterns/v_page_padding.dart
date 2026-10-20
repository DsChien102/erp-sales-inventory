import 'package:flutter/material.dart';
// contract: na tone/emphasis/state

import '../foundation/v_inspector_scope.dart';
import '../tokens/v_spacing.dart';

/// Standard screen inset padding.
///
/// Horizontal defaults to [VSpacing.screenMobile]; pass [horizontal] to override.
/// On tablets the outer gutter comes from [VPageScaffold]'s content column, so
/// this inset stays 16 at every width.
class VPagePadding extends StatelessWidget {
  const VPagePadding({
    super.key,
    required this.child,
    this.horizontal,
    this.vertical,
    this.applyBottomSafeArea = false,
  });

  final Widget child;

  /// Override horizontal inset; defaults to [VSpacing.screenMobile].
  final double? horizontal;

  /// Optional vertical padding in addition to horizontal.
  final double? vertical;

  final bool applyBottomSafeArea;

  @override
  Widget build(BuildContext context) {
    final h = horizontal ?? VSpacing.screenMobile;
    final v = vertical ?? 0.0;

    Widget padded = Padding(
      padding: EdgeInsets.symmetric(horizontal: h, vertical: v),
      child: vInspectorShow(child),
    );

    if (applyBottomSafeArea) {
      padded = SafeArea(top: false, child: padded);
    }

    return vInspectorHide(padded);
  }
}
