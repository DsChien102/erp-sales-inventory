import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/errors/exception_mapper.dart';
import '../bloc/iam_feature_access_cubit.dart';
import '../bloc/iam_feature_access_state.dart';

class MorePage extends StatelessWidget {
  const MorePage({
    super.key,
    this.iamModule,
    this.accessCubit,
    this.tenantBlocked = false,
  });

  final IIamModule? iamModule;
  final IamFeatureAccessCubit? accessCubit;
  final bool tenantBlocked;

  Future<void> _logout(BuildContext context) async {
    final result = await guard(
      () => (iamModule ?? getIt<IIamModule>()).executeCommandAsync<SignOutResultDto>(
        SignOutCommand(),
      ),
    );

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
      (signOut) {
        if (!signOut.localCleared) {
          VToast.show(
            context,
            title: 'Đăng xuất thất bại',
            message: 'Không thể đóng phiên trên máy.',
            type: VToastType.danger,
          );
          return;
        }
        if (!signOut.remoteSucceeded) {
          VToast.show(
            context,
            title: 'Cảnh báo',
            message: 'Phiên trên máy đã đóng; máy chủ chưa xác nhận đăng xuất',
            type: VToastType.warning,
          );
        }
        context.go('/login');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (accessCubit != null) {
      return BlocProvider.value(
        value: accessCubit!,
        child: _MoreView(
          onLogout: _logout,
          tenantBlocked: tenantBlocked,
        ),
      );
    }

    return BlocProvider(
      create: (_) {
        final cubit = IamFeatureAccessCubit(iamModule: iamModule ?? getIt<IIamModule>());
        // Tổ chức bị chặn: mọi RPC theo tổ chức đều bị từ chối → không gọi.
        if (!tenantBlocked) cubit.load();
        return cubit;
      },
      child: _MoreView(
        onLogout: _logout,
        tenantBlocked: tenantBlocked,
      ),
    );
  }
}

class _MoreView extends StatelessWidget {
  const _MoreView({
    required this.onLogout,
    required this.tenantBlocked,
  });

  final Future<void> Function(BuildContext context) onLogout;
  final bool tenantBlocked;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IamFeatureAccessCubit, IamFeatureAccessState>(
      builder: (context, access) {
        final blocked = tenantBlocked;
        final menuItems = <_MoreMenuItem>[
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

class _MoreMenuItem extends StatelessWidget {
  const _MoreMenuItem({
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
