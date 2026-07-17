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
                Text(
                  'Hồ sơ còn thiếu thông tin',
                  style: VTypography.bodyDefault.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Thiếu MST và địa chỉ hóa đơn. Một số thông tin có thể cần bổ sung trong tính năng này.',
                  style: VTypography.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Bổ sung ngay',
                      style: VTypography.bodyDefault.copyWith(
                        color: colors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
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

  static const message =
      'KH & NCC này sẽ không được chọn cho giao dịch mới.';

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
            child: Text(
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
