import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Bottom Sheet Cảnh báo mã số thuế trùng (TA-O-02).
class TaxCodeDuplicateWarningBottomSheet extends StatelessWidget {
  final VoidCallback? onSaveAnyway;
  final VoidCallback? onReview;

  const TaxCodeDuplicateWarningBottomSheet({
    super.key,
    this.onSaveAnyway,
    this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Padding(
      padding: const EdgeInsets.only(
        left: VSpacing.space4,
        right: VSpacing.space4,
        top: VSpacing.space2,
        bottom: VSpacing.space6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VText(
            'Mã số thuế đã được ghi nhận',
            variant: VTextVariant.headingH3,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const VGap.xs(),
          VText(
            'Mã số thuế này đã xuất hiện ở hồ sơ khác. Hệ thống không tiết lộ tổ chức liên quan.',
            variant: VTextVariant.bodySmall,
            color: colors.textSecondary,
          ),
          const VGap.md(),

          // Alert Box
          Container(
            padding: const EdgeInsets.all(VSpacing.space4),
            decoration: BoxDecoration(
              color: colors.warningBg,
              borderRadius: BorderRadius.circular(VRadius.card),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VIcon(
                  icon: VIcons.warning,
                  size: 20,
                  color: colors.warning,
                ),
                const VGap.horizontalSm(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VText(
                        'Có thể tiếp tục lưu',
                        variant: VTextVariant.bodyDefault,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: colors.warning,
                        ),
                      ),
                      const VGap.xs(),
                      VText(
                        'Mã số thuế không bắt buộc duy nhất. Hãy kiểm tra lại trước khi tiếp tục.',
                        variant: VTextVariant.bodySmall,
                        color: colors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const VGap.lg(),

          // Action 1: Vẫn lưu
          VButton(
            label: 'Vẫn lưu',
            variant: VButtonVariant.primary,
            tone: VComponentTone.success,
            fullWidth: true,
            onPressed: () {
              Navigator.of(context).pop();
              onSaveAnyway?.call();
            },
          ),
          const VGap.sm(),

          // Action 2: Kiểm tra lại
          VButton(
            label: 'Kiểm tra lại',
            variant: VButtonVariant.outline,
            fullWidth: true,
            onPressed: () {
              Navigator.of(context).pop();
              onReview?.call();
            },
          ),
        ],
      ),
    );
  }
}
