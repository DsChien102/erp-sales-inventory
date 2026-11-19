import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

/// SC-06 — Xác nhận thoát form tạo/sửa giá riêng khi còn thay đổi chưa lưu.
/// Sử dụng [showVBottomSheet] theo chuẩn Design System.
Future<bool> showPriceRuleLeaveFormDialog(BuildContext context) async {
  final result = await showVBottomSheet<bool>(
    context: context,
    title: 'Rời khỏi màn hình?',
    child: const _PriceRuleLeaveFormSheet(),
  );
  return result ?? false;
}

class _PriceRuleLeaveFormSheet extends StatelessWidget {
  const _PriceRuleLeaveFormSheet();

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          VSpacing.space4,
          VSpacing.space3,
          VSpacing.space4,
          VSpacing.space4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VText(
              'Những thay đổi chưa lưu sẽ bị mất.',
              variant: VTextVariant.bodyDefault,
              color: colors.textSecondary,
            ),
            const SizedBox(height: VSpacing.space6),
            Row(
              children: [
                Expanded(
                  child: VButton(
                    label: 'Ở lại chỉnh sửa',
                    variant: VButtonVariant.secondary,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: VSpacing.space3),
                Expanded(
                  child: VButton(
                    label: 'Rời khỏi',
                    variant: VButtonVariant.primary,
                    tone: VComponentTone.danger,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
