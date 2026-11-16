import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

const assistantFooterText =
    'Trợ lý AI có thể hiểu nhầm câu hỏi. Số liệu trong bảng lấy trực tiếp từ dữ liệu cửa hàng.';

/// Hiện số lượt còn lại khi ≤ [remainingThreshold].
class AssistantFooter extends StatelessWidget {
  const AssistantFooter({super.key, this.remaining});

  static const remainingThreshold = 10;

  final int? remaining;

  @override
  Widget build(BuildContext context) {
    final c = context.vColors;
    final showRemaining = remaining != null && remaining! <= remainingThreshold;
    return Container(
      color: c.surface,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(VSpacing.md, 0, VSpacing.md, VSpacing.sm),
      child: Column(
        children: [
          if (showRemaining)
            VText(
              'Còn $remaining câu hỏi hôm nay.',
              variant: VTextVariant.caption,
              color: c.textSecondary,
              textAlign: TextAlign.center,
            ),
          VText(
            assistantFooterText,
            variant: VTextVariant.caption,
            color: c.textMuted,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
