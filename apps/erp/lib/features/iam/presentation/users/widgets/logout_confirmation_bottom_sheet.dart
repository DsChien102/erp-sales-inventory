import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

/// Logout confirmation bottom sheet (TA-D-08 / EP-06 US-04).
Future<void> showLogoutConfirmationBottomSheet({
  required BuildContext context,
  required VoidCallback onConfirm,
}) {
  return showVAdaptiveSheet<void>(
    context: context,
    child: Builder(
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.screenMobile,
          vertical: VSpacing.space4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: VText(
                'Đăng xuất khỏi Mosaic Retail?',
                variant: VTextVariant.headingH3,
                color: context.vColors.danger,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const VGap.xs(),
            VText(
              'Bạn sẽ cần đăng nhập lại để tiếp tục sử dụng ứng dụng.',
              variant: VTextVariant.bodySmall,
              color: context.vColors.textSecondary,
            ),
            const VGap.xl(),
            Row(
              children: [
                Expanded(
                  child: VButton(
                    label: 'Quay lại',
                    variant: VButtonVariant.secondary,
                    size: VButtonSize.large,
                    fullWidth: true,
                    onPressed: () => Navigator.of(sheetContext).pop(),
                  ),
                ),
                const VGap.horizontalSm(),
                Expanded(
                  child: VButton(
                    label: 'Đăng xuất',
                    variant: VButtonVariant.primary,
                    tone: VComponentTone.danger,
                    size: VButtonSize.large,
                    fullWidth: true,
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      onConfirm();
                    },
                  ),
                ),
              ],
            ),
            const VGap.md(),
          ],
        ),
      ),
    ),
  );
}
