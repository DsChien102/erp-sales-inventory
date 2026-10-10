import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/session/session_controller.dart';
import '../bloc/iam_feature_access_cubit.dart';
import '../bloc/iam_feature_access_state.dart';

class MorePage extends StatelessWidget {
  const MorePage({
    super.key,
    this.session,
    this.accessCubit,
    this.tenantBlocked = false,
    this.isPlatformAdmin = false,
  });

  final SessionController? session;
  final IamFeatureAccessCubit? accessCubit;
  final bool tenantBlocked;

  /// Hiện nhóm "Quản trị nền tảng" (A1). RPC vẫn tự kiểm quyền (BR-60).
  final bool isPlatformAdmin;

  Future<void> _logout(BuildContext context) async {
    try {
      final result = await getIt<SessionController>().signOut();
      if (!context.mounted) return;
      if (!result.localCleared) {
        VToast.show(
          context,
          title: 'Đăng xuất thất bại',
          message: 'Không thể đóng phiên trên máy.',
          type: VToastType.danger,
        );
        return;
      }
      if (!result.remoteSucceeded) {
        VToast.show(
          context,
          title: 'Cảnh báo',
          message: 'Phiên trên máy đã đóng; máy chủ chưa xác nhận đăng xuất',
          type: VToastType.warning,
        );
      }
      context.go('/login');
    } on AppException catch (error) {
      if (!context.mounted) return;
      VToast.show(
        context,
        title: 'Đăng xuất thất bại',
        message: error.userMessage(),
        type: VToastType.danger,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (accessCubit != null) {
      return BlocProvider.value(
        value: accessCubit!,
        child: _MoreView(
          onLogout: _logout,
          tenantBlocked: tenantBlocked,
          isPlatformAdmin: isPlatformAdmin,
        ),
      );
    }

    return BlocProvider(
      create: (_) {
        final cubit = IamFeatureAccessCubit(
          session: session ?? getIt<SessionController>(),
        );
        // Tổ chức bị chặn: mọi RPC theo tổ chức đều bị từ chối → không gọi.
        if (!tenantBlocked) cubit.load();
        return cubit;
      },
      child: _MoreView(
        onLogout: _logout,
        tenantBlocked: tenantBlocked,
        isPlatformAdmin: isPlatformAdmin,
      ),
    );
  }
}

class _MoreView extends StatelessWidget {
  const _MoreView({
    required this.onLogout,
    required this.tenantBlocked,
    required this.isPlatformAdmin,
  });

  final Future<void> Function(BuildContext context) onLogout;
  final bool tenantBlocked;
  final bool isPlatformAdmin;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IamFeatureAccessCubit, IamFeatureAccessState>(
      builder: (context, access) {
        final blocked = tenantBlocked;
        final menuItems = <Widget>[
          const _MoreMenuItem(
            icon: VIcons.people,
            title: 'Khách hàng & NCC',
            subtitle: 'Quản lý khách hàng & nhà cung cấp',
            enabled: false,
          ),
          const _MoreMenuItem(
            icon: VIcons.download,
            title: 'Đơn nhập',
            subtitle: 'Nhập kho từ nhà cung cấp',
            enabled: false,
          ),
          const _MoreMenuItem(
            icon: VIcons.warehouse,
            title: 'Kho',
            subtitle: 'Tồn kho, phiếu nhập, điều chỉnh',
            enabled: false,
          ),
          const _MoreMenuItem(
            icon: VIcons.chart,
            title: 'Báo cáo',
            subtitle: 'Doanh thu, tồn kho, công nợ',
            enabled: false,
          ),
          _MoreMenuItem(
            icon: VIcons.tag,
            title: 'Giá riêng / Nhớ giá',
            subtitle: 'Giá riêng theo khách hàng & nhớ giá bán',
            onTap: blocked ? null : () => context.push('/pricing'),
          ),
          if (access.canOpenIamHub || blocked)
            _MoreMenuItem(
              icon: VIcons.people,
              title: 'Người dùng & vai trò',
              subtitle: 'Quản lý thành viên và quyền truy cập',
              onTap: blocked ? null : () => context.push('/more/users-and-roles'),
            ),
          _MoreMenuItem(
            icon: VIcons.person,
            title: 'Tài khoản của tôi',
            subtitle: 'Xem và chỉnh sửa thông tin cá nhân',
            onTap: () => context.push('/more/my-account'),
          ),
          _MoreMenuItem(
            icon: VIcons.settings,
            title: 'Thiết lập',
            subtitle: 'Cấu hình hệ thống & hóa đơn điện tử',
            onTap: blocked ? null : () => context.push('/more/settings'),
          ),
          if (isPlatformAdmin) ...[
            const _MoreSectionHeader('QUẢN TRỊ NỀN TẢNG'),
            _MoreMenuItem(
              key: const Key('more_platform_organizations'),
              icon: VIcons.apartment,
              title: 'Tổ chức',
              subtitle: 'Tạm ngừng, khôi phục, đóng, chuyển chủ sở hữu',
              onTap: () => context.push('/more/platform/organizations'),
            ),
          ],
          _MoreMenuItem(
            icon: VIcons.logout,
            title: 'Đăng xuất',
            subtitle: 'Thoát khỏi tài khoản hiện tại',
            isDestructive: true,
            onTap: () => onLogout(context),
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
      },
    );
  }
}

class _MoreSectionHeader extends StatelessWidget {
  const _MoreSectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: VSpacing.space2),
      child: VText(
        label,
        variant: VTextVariant.caption,
        color: context.vColors.textSecondary,
        style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
      ),
    );
  }
}

class _MoreMenuItem extends StatelessWidget {
  const _MoreMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.enabled = true,
    this.isDestructive = false,
  });

  final VIcons icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool enabled;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;
    final isEnabled = enabled && onTap != null;
    final titleColor = isDestructive ? dynamicColors.danger : dynamicColors.textPrimary;
    final iconColor = isDestructive ? dynamicColors.danger : dynamicColors.primary;
    final iconBackgroundColor = isDestructive ? dynamicColors.dangerBg : dynamicColors.surfaceBrand;

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
              icon: icon,
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
                  VText(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    variant: VTextVariant.headingH4,
                    color: titleColor,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const VGap.xs(),
                  VText(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    variant: VTextVariant.bodySmall,
                    color: dynamicColors.textSecondary,
                  ),
                ],
              ),
            ),
            if (isEnabled) ...[
              const SizedBox(width: VSpacing.space2),
              VIcon(
                icon: VIcons.chevronRight,
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
