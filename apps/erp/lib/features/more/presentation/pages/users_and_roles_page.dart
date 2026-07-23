import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

/// Trang Quản lý "Người dùng & vai trò" trong ERP App tuân thủ 100% Design System với VPageScaffold.
class UsersAndRolesPage extends StatelessWidget {
  const UsersAndRolesPage({super.key});

  void _showNotice(BuildContext context, String featureName) {
    VToast.show(
      context,
      title: featureName,
      message: 'Tính năng đang được khởi tạo.',
      type: VToastType.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    final menuItems = [
      (
        icon: VIcons.apartment,
        title: 'Hồ sơ tổ chức',
        subtitle: 'Thông tin liên hệ và địa chỉ tổ chức',
      ),
      (
        icon: VIcons.people,
        title: 'Người dùng',
        subtitle: 'Thành viên, lời mời và quyền truy cập',
      ),
      (
        icon: VIcons.shield,
        title: 'Vai trò',
        subtitle: 'Phạm vi thao tác theo từng vai trò',
      ),
      (
        icon: VIcons.lock,
        title: 'Quyền sở hữu',
        subtitle: 'Chủ tổ chức và chuyển quyền sở hữu',
      ),
      (
        icon: VIcons.listView,
        title: 'Lịch sử quản trị',
        subtitle: 'Theo dõi thay đổi người dùng và quyền',
      ),
    ];

    return VPageScaffold(
      title: 'Người dùng & vai trò',
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.screenMobile,
          vertical: VSpacing.space4,
        ),
        children: [
          // Banner cảnh báo Cần hoàn tất thiết lập
          VCard(
            backgroundColor: colors.warningBg,
            padding: const EdgeInsets.all(VSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(
                  'Cần hoàn tất',
                  variant: VTextVariant.bodySmall,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colors.warning,
                  ),
                ),
                const VGap.xs(),
                VText(
                  'Tổ chức chưa hoàn tất thiết lập',
                  variant: VTextVariant.headingH4,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const VGap.xs(),
                VText(
                  'Còn 1 điều kiện bắt buộc trước khi có thể bắt đầu vận hành.',
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
                const VGap.sm(),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => _showNotice(context, 'Hoàn tất thiết lập tổ chức'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        VText(
                          'Xem và hoàn tất',
                          variant: VTextVariant.bodySmall,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colors.primary,
                          ),
                        ),
                        const VGap.horizontalXs(),
                        VIcon(
                          icon: VIcons.chevronRight,
                          size: 16,
                          color: colors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const VGap.sm(),

          // 5 Card danh mục tùy chọn
          for (int i = 0; i < menuItems.length; i++) ...[
            VCard(
              onTap: () {
                if (menuItems[i].title == 'Hồ sơ tổ chức') {
                  context.push('/more/organization-profile');
                } else if (menuItems[i].title == 'Người dùng') {
                  context.push('/more/users');
                } else {
                  _showNotice(context, menuItems[i].title);
                }
              },
              padding: const EdgeInsets.symmetric(
                horizontal: VSpacing.space4,
                vertical: VSpacing.space4,
              ),
              child: Row(
                children: [
                  VIcon(
                    icon: menuItems[i].icon,
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
                          menuItems[i].title,
                          variant: VTextVariant.bodyDefault,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                        const VGap.xs(),
                        VText(
                          menuItems[i].subtitle,
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
            if (i < menuItems.length - 1) const VGap.sm(),
          ],
        ],
      ),
    );
  }
}
