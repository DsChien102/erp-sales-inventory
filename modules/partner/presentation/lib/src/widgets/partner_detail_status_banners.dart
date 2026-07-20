import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Warning when profile is missing tax/invoice fields (D-03).
class PartnerDetailWarningBanner extends StatelessWidget {
  const PartnerDetailWarningBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Container(
      padding: const EdgeInsets.all(VSpacing.space4),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(VRadius.card),
        border: Border.all(color: colors.warning.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VIcon(icon: VIcons.warning, color: colors.warning, size: 22),
          const SizedBox(width: VSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(
                  'Hồ sơ còn thiếu thông tin',
                  variant: VTextVariant.bodyDefault,
                  color: colors.textPrimary,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: VSpacing.space1),
                VText(
                  'Thiếu MST và địa chỉ hóa đơn. Một số thông tin có thể cần bổ sung trong tính năng này.',
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
                const VGap.sm(),
                Row(
                  children: [
                    VText(
                      'Bổ sung ngay',
                      variant: VTextVariant.bodyDefault,
                      color: colors.success,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const VGap.horizontalXs(),
                    VIcon(
                      icon: VIcons.chevronRight,
                      size: 16,
                      color: colors.success,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner when partner is inactive (SG-07 / D-04).
class PartnerDetailInactiveBanner extends StatelessWidget {
  const PartnerDetailInactiveBanner({super.key});

  static const message = 'KH & NCC này sẽ không được chọn cho giao dịch mới.';

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Container(
      key: const Key('wgt_e02_u01_fr02_01'),
      padding: const EdgeInsets.all(VSpacing.space4),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(VRadius.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VIcon(icon: VIcons.warning, color: colors.warning, size: 22),
          const SizedBox(width: VSpacing.space3),
          Expanded(
            child: VText(
              message,
              style: VTypography.bodyDefault.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
