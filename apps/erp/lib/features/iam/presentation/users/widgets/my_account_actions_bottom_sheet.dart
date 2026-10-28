import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Account actions bottom sheet (edit / reset password / logout).
Future<void> showMyAccountActionsBottomSheet({
  required BuildContext context,
  required VoidCallback onEditProfile,
  required VoidCallback onResetPassword,
  required VoidCallback onLogout,
}) {
  return showVBottomSheet<void>(
    context: context,
    child: Padding(
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
              'Thao tác tài khoản',
              variant: VTextVariant.headingH3,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const VGap.md(),
          VCard(
            onTap: () {
              Navigator.of(context).pop();
              onEditProfile();
            },
            padding: const EdgeInsets.all(VSpacing.space4),
            child: Row(
              children: [
                VIcon(
                  icon: VIcons.edit,
                  size: 20,
                  color: context.vColors.textPrimary,
                ),
                const SizedBox(width: VSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VText(
                        'Chỉnh sửa thông tin cá nhân',
                        variant: VTextVariant.bodyDefault,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const VGap.xs(),
                      VText(
                        'Cập nhật hồ sơ cá nhân',
                        variant: VTextVariant.bodySmall,
                        color: context.vColors.textSecondary,
                      ),
                    ],
                  ),
                ),
                VIcon(
                  icon: VIcons.chevronRight,
                  size: 20,
                  color: context.vColors.textSecondary,
                ),
              ],
            ),
          ),
          const VGap.sm(),
          VCard(
            onTap: () {
              Navigator.of(context).pop();
              onResetPassword();
            },
            padding: const EdgeInsets.all(VSpacing.space4),
            child: Row(
              children: [
                VIcon(
                  icon: VIcons.lock,
                  size: 20,
                  color: context.vColors.textPrimary,
                ),
                const SizedBox(width: VSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VText(
                        'Đặt lại mật khẩu',
                        variant: VTextVariant.bodyDefault,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const VGap.xs(),
                      VText(
                        'Xác minh email và tạo mật khẩu mới',
                        variant: VTextVariant.bodySmall,
                        color: context.vColors.textSecondary,
                      ),
                    ],
                  ),
                ),
                VIcon(
                  icon: VIcons.chevronRight,
                  size: 20,
                  color: context.vColors.textSecondary,
                ),
              ],
            ),
          ),
          const VGap.sm(),
          Container(
            decoration: BoxDecoration(
              color: context.vColors.dangerBg,
              borderRadius: BorderRadius.circular(VRadius.card),
              border: Border.all(color: context.vColors.danger),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  onLogout();
                },
                borderRadius: BorderRadius.circular(VRadius.card),
                child: Padding(
                  padding: const EdgeInsets.all(VSpacing.space4),
                  child: Row(
                    children: [
                      VIcon(
                        icon: VIcons.logout,
                        size: 20,
                        color: context.vColors.danger,
                      ),
                      const SizedBox(width: VSpacing.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            VText(
                              'Đăng xuất',
                              variant: VTextVariant.bodyDefault,
                              color: context.vColors.danger,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const VGap.xs(),
                            VText(
                              'Kết thúc phiên sử dụng hiện tại',
                              variant: VTextVariant.bodySmall,
                              color: context.vColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                      VIcon(
                        icon: VIcons.chevronRight,
                        size: 20,
                        color: context.vColors.danger,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const VGap.lg(),
        ],
      ),
    ),
  );
}
