import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../../../core/di/injection.dart';
import '../../../auth/domain/usecases/sign_out_use_case.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  Future<void> _logout(BuildContext context) async {
    final result = await getIt<SignOutUseCase>()();

    if (!context.mounted) return;

    result.fold(
      (failure) {
        VToast.show(
          context,
          title: 'Đăng xuất thất bại',
          message: failure.message,
          type: VToastType.danger,
        );
      },
      (_) => context.go('/login'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      const _MoreMenuItem(
        icon: Icons.group_outlined,
        title: 'Khách hàng & NCC',
        subtitle: 'Quản lý khách hàng & nhà cung cấp',
        enabled: false,
      ),
      const _MoreMenuItem(
        icon: Icons.download_rounded,
        title: 'Đơn nhập',
        subtitle: 'Nhập kho từ nhà cung cấp',
        enabled: false,
      ),
      const _MoreMenuItem(
        icon: Icons.warehouse_outlined,
        title: 'Kho',
        subtitle: 'Tồn kho, phiếu nhập, điều chỉnh',
        enabled: false,
      ),
      const _MoreMenuItem(
        icon: Icons.bar_chart_outlined,
        title: 'Báo cáo',
        subtitle: 'Doanh thu, tồn kho, công nợ',
        enabled: false,
      ),
      _MoreMenuItem(
        icon: Icons.settings_outlined,
        title: 'Thiết lập',
        subtitle: 'Cấu hình hệ thống & hóa đơn điện tử',
        onTap: () => context.push('/more/settings'),
      ),
      _MoreMenuItem(
        icon: Icons.logout_rounded,
        title: 'Đăng xuất',
        subtitle: 'Thoát khỏi tài khoản hiện tại',
        isDestructive: true,
        onTap: () => _logout(context),
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.screenMobile,
        vertical: VSpacing.space4,
      ),
      itemCount: menuItems.length,
      separatorBuilder: (context, index) => const SizedBox(height: VSpacing.space3),
      itemBuilder: (context, index) => menuItems[index],
    );
  }

}

class _MoreMenuItem extends StatelessWidget {
  const _MoreMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.enabled = true,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool enabled;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final isEnabled = enabled && onTap != null;
    final titleColor = isDestructive ? VColors.danger : dynamicColors.textPrimary;
    final iconColor = isDestructive ? VColors.danger : dynamicColors.primary;
    final iconBackgroundColor =
        isDestructive ? VColors.dangerBg : dynamicColors.surfaceBrand;

    return Opacity(
      opacity: isEnabled ? 1 : 0.45,
      child: VCard(
        onTap: isEnabled ? onTap : null,
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.space4,
          vertical: VSpacing.space3 + 2,
        ),
        child: Row(
          children: [
            VIconBox(
              iconData: icon,
              size: 44,
              iconSize: 20,
              backgroundColor: iconBackgroundColor,
              iconColor: iconColor,
              borderRadius: VRadius.r12,
            ),
            const SizedBox(width: VSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VTypography.headingH4.copyWith(
                      color: titleColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VTypography.bodySmall.copyWith(
                      color: dynamicColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isEnabled) ...[
              const SizedBox(width: VSpacing.space2),
              Icon(
                Icons.chevron_right,
                color: dynamicColors.textSecondary,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
