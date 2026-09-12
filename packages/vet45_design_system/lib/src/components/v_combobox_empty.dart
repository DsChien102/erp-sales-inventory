import 'package:flutter/material.dart';

import '../foundation/v_context_extensions.dart';
import '../primitives/v_text.dart';
import '../tokens/v_spacing.dart';

/// Empty-result content for [VCombobox] overlay when the filter matches nothing.
///
/// Custom [VCombobox.empty] widgets should target roughly [preferredHeight]
/// so [MenuAnchor] shell sizing stays stable.
class VComboboxEmpty extends StatelessWidget {
  /// Vertical padding applied around the message.
  static const double _verticalPadding = VSpacing.space2;

  /// Line box for [VTextVariant.bodyDefault] (14px × height 22/14).
  static const double _lineHeight = 22;

  /// Stable height for overlay shell layout (`padding × 2 + line height`).
  static const double preferredHeight = _verticalPadding * 2 + _lineHeight;

  const VComboboxEmpty({super.key, this.message});

  /// Shown message; defaults to Vietnamese empty copy.
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space2,
        vertical: _verticalPadding,
      ),
      child: VText(
        message ?? 'Không tìm thấy kết quả',
        variant: VTextVariant.bodyDefault,
        color: context.vColors.textMuted,
      ),
    );
  }
}
