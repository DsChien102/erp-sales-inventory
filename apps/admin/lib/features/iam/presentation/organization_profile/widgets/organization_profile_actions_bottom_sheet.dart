import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Bottom Sheet Thao tác hồ sơ tổ chức (TA-O-01).
class OrganizationProfileActionsBottomSheet extends StatelessWidget {
  final bool hasLegalProfile;
  final VoidCallback? onEditInfoTap;
  final VoidCallback? onAddLegalTap;

  const OrganizationProfileActionsBottomSheet({
    super.key,
    this.hasLegalProfile = false,
    this.onEditInfoTap,
    this.onAddLegalTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    final legalTitle = hasLegalProfile ? 'Chỉnh sửa hồ sơ pháp lý' : 'Thêm hồ sơ pháp lý';
    final legalSubtitle = hasLegalProfile ? 'Cập nhật thông tin pháp lý' : 'Bổ sung thông tin pháp lý';

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
            'Thao tác hồ sơ',
            variant: VTextVariant.headingH3,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const VGap.md(),

          // Option 1: Chỉnh sửa thông tin tổ chức
          VCard(
            onTap: () {
              Navigator.of(context).pop();
              onEditInfoTap?.call();
            },
            padding: const EdgeInsets.all(VSpacing.space4),
            child: Row(
              children: [
                VIcon(
                  icon: VIcons.edit,
                  size: 20,
                  color: colors.textPrimary,
                ),
                const VGap.horizontalSm(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VText(
                        'Chỉnh sửa thông tin tổ chức',
                        variant: VTextVariant.bodyDefault,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const VGap.xs(),
                      VText(
                        'Cập nhật thông tin liên hệ và địa chỉ',
                        variant: VTextVariant.bodySmall,
                        color: colors.textSecondary,
                      ),
                    ],
                  ),
                ),
                VIcon(
                  icon: VIcons.chevronRight,
                  size: 20,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
          const VGap.sm(),

          // Option 2: Thêm / Chỉnh sửa hồ sơ pháp lý
          VCard(
            onTap: () {
              Navigator.of(context).pop();
              onAddLegalTap?.call();
            },
            padding: const EdgeInsets.all(VSpacing.space4),
            child: Row(
              children: [
                VIcon(
                  icon: VIcons.description,
                  size: 20,
                  color: colors.textPrimary,
                ),
                const VGap.horizontalSm(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VText(
                        legalTitle,
                        variant: VTextVariant.bodyDefault,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const VGap.xs(),
                      VText(
                        legalSubtitle,
                        variant: VTextVariant.bodySmall,
                        color: colors.textSecondary,
                      ),
                    ],
                  ),
                ),
                VIcon(
                  icon: VIcons.chevronRight,
                  size: 20,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
