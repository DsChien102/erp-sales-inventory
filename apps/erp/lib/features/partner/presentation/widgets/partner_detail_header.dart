import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import '../bloc/partner_list_state.dart';

class PartnerDetailHeader extends StatelessWidget {
  final PartnerItemModel partner;

  const PartnerDetailHeader({
    super.key,
    required this.partner,
  });

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    
    final roleColor = partner.role == 'Khách hàng'
        ? VColors.info
        : (partner.role == 'Nhà cung cấp' ? VColors.warning : VColors.primary);
    final roleBgColor = partner.role == 'Khách hàng'
        ? VColors.infoBg
        : (partner.role == 'Nhà cung cấp' ? VColors.warningBg : VColors.successBg); // Use successBg if primary100 not guaranteed
        
    final statusColor = partner.status == 'Đang hoạt động' ? VColors.success : dynamicColors.textSecondary;
    final statusBgColor = partner.status == 'Đang hoạt động' ? VColors.successBg : dynamicColors.borderDefault;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: VSpacing.space4, vertical: VSpacing.space4),
      decoration: BoxDecoration(
        color: dynamicColors.surface,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: VColors.successBg,
            child: Text(
              partner.avatarText,
              style: VTypography.headingH4.copyWith(
                color: VColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: VSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partner.name,
                  style: VTypography.headingH4.copyWith(
                    fontWeight: FontWeight.w700,
                    color: dynamicColors.textPrimary,
                  ),
                ),
                const SizedBox(height: VSpacing.space2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: roleBgColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        partner.role,
                        style: VTypography.bodySmall.copyWith(
                          color: roleColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: VSpacing.space2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        partner.status,
                        style: VTypography.bodySmall.copyWith(
                          color: statusColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: VSpacing.space2),
                Text(
                  partner.phone,
                  style: VTypography.bodyDefault.copyWith(
                    color: dynamicColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
