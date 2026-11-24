import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/session/session_controller.dart';
import '../bloc/iam_feature_access_cubit.dart';
import '../bloc/iam_feature_access_state.dart';

/// Trang Quản lý "Người dùng & vai trò" — gated theo session permissions.
class UsersAndRolesPage extends StatelessWidget {
  const UsersAndRolesPage({
    super.key,
    this.session,
    this.accessCubit,
  });

  final SessionController? session;
  final IamFeatureAccessCubit? accessCubit;

  @override
  Widget build(BuildContext context) {
    if (accessCubit != null) {
      return BlocProvider.value(
        value: accessCubit!,
        child: const _UsersAndRolesView(),
      );
    }

    return BlocProvider(
      create: (_) => IamFeatureAccessCubit(
        session: session ?? getIt<SessionController>(),
      )..load(),
      child: const _UsersAndRolesView(),
    );
  }
}

class _UsersAndRolesView extends StatelessWidget {
  const _UsersAndRolesView();

  Future<void> _pushAndReload(BuildContext context, String route) async {
    await context.push(route);
    if (context.mounted) {
      await context.read<IamFeatureAccessCubit>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IamFeatureAccessCubit, IamFeatureAccessState>(
      builder: (context, access) {
        final items = <_HubMenuItem>[
          if (access.canViewTenantProfile)
            _HubMenuItem(
              icon: VIcons.apartment,
              title: 'Hồ sơ tổ chức',
              subtitle: 'Thông tin liên hệ và địa chỉ tổ chức',
              onTap: () => _pushAndReload(context, '/more/organization-profile'),
            ),
          if (access.canViewMembers)
            _HubMenuItem(
              icon: VIcons.people,
              title: 'Người dùng',
              subtitle: 'Thành viên, lời mời và quyền truy cập',
              onTap: () => _pushAndReload(context, '/more/users'),
            ),
          if (access.canViewMembers)
            _HubMenuItem(
              icon: VIcons.shield,
              title: 'Vai trò',
              subtitle: 'Phạm vi thao tác theo từng vai trò',
              onTap: () => _pushAndReload(context, '/more/roles'),
            ),
          if (access.canViewTenantAudit)
            _HubMenuItem(
              icon: VIcons.listView,
              title: 'Lịch sử quản trị',
              subtitle: 'Theo dõi thay đổi người dùng và quyền',
              onTap: () => _pushAndReload(context, '/more/audit-logs'),
            ),
        ];

        return VPageScaffold(
          title: 'Người dùng & vai trò',
          // Web ≥ 1024: mở từ menu "Quản lý" của thanh biểu tượng, không có trang Thêm để quay về (10-8c).
          showBackButton: MediaQuery.sizeOf(context).width < VBreakpoints.desktop,
          body: RefreshIndicator(
            onRefresh: () => context.read<IamFeatureAccessCubit>().load(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: VSpacing.screenMobile,
                vertical: VSpacing.space4,
              ),
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  _HubMenuCard(item: items[i]),
                  if (i < items.length - 1) const VGap.sm(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

}

final class _HubMenuItem {
  const _HubMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final VIcons icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class _HubMenuCard extends StatelessWidget {
  const _HubMenuCard({required this.item});

  final _HubMenuItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return VCard(
      onTap: item.onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space4,
        vertical: VSpacing.space4,
      ),
      child: Row(
        children: [
          VIcon(icon: item.icon, size: 20, color: colors.textPrimary),
          const VGap.horizontalSm(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                VText(
                  item.title,
                  variant: VTextVariant.bodyDefault,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const VGap.xs(),
                VText(
                  item.subtitle,
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
    );
  }
}
