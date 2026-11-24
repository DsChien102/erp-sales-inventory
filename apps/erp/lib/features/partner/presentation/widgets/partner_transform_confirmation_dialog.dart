import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

class PartnerTransformConfirmationDialog extends StatelessWidget {
  const PartnerTransformConfirmationDialog({
    super.key,
    required this.onBack,
    required this.onConfirm,
  });

  final VoidCallback onBack;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: VSpacing.space5),
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VRadius.sheet),
      ),
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.space5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              child: VIconBox(
                icon: VIcons.warning,
                size: 58,
                iconSize: 32,
                isCircular: true,
                backgroundColor: colors.warningBg,
                iconColor: colors.warning,
                borderColor: colors.warning,
                borderWidth: 2,
              ),
            ),
            const SizedBox(height: VSpacing.space4),
            VText(
              'Xác nhận chuyển thành tổ chức?',
              textAlign: TextAlign.center,
              variant: VTextVariant.headingH3,
              color: colors.textPrimary,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: VSpacing.space4),
            VText(
              'Hồ sơ hiện tại sẽ trở thành Tổ chức.',
              variant: VTextVariant.bodyDefault,
              color: colors.textSecondary,
            ),
            const SizedBox(height: VSpacing.space3),
            VText(
              'Thông tin cá nhân hiện tại sẽ được lưu làm Người liên hệ chính.',
              variant: VTextVariant.bodyDefault,
              color: colors.textSecondary,
            ),
            const SizedBox(height: VSpacing.space3),
            VText(
              'Lịch sử giao dịch, hóa đơn và công nợ vẫn được giữ nguyên.',
              variant: VTextVariant.bodyDefault,
              color: colors.textSecondary,
            ),
            const SizedBox(height: VSpacing.space5),
            Row(
              children: [
                Expanded(
                  child: VButton(
                    key: const Key('transform_confirmation_back'),
                    label: 'Quay lại',
                    variant: VButtonVariant.secondary,
                    foregroundColor: colors.success,
                    onPressed: onBack,
                  ),
                ),
                const SizedBox(width: VSpacing.space3),
                Expanded(
                  child: VButton(
                    key: const Key('transform_confirmation_confirm'),
                    label: 'Xác nhận chuyển',
                    onPressed: onConfirm,
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
