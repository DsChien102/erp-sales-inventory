import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';

import '../../../../core/di/injection.dart';
import '../bloc/iam_feature_access_cubit.dart';
import '../bloc/iam_feature_access_state.dart';

/// Trang Quản lý "Người dùng & vai trò" — gated theo session permissions.
class UsersAndRolesPage extends StatelessWidget {
  const UsersAndRolesPage({super.key, this.iamModule, this.accessCubit});

  final IIamModule? iamModule;
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
      create: (_) => IamFeatureAccessCubit(iamModule: iamModule ?? getIt<IIamModule>())..load(),
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
        final colors = context.vColors;
        final readinessBanner = access.readinessBanner;
        final showReadinessSkeleton = access.showReadinessSkeleton;

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
              onTap: () => _showComingSoonToast(context),
            ),
          if (access.canViewTenantProfile)
            _HubMenuItem(
              icon: VIcons.shield,
              title: 'Quyền sở hữu',
              subtitle: 'Chủ tổ chức và chuyển quyền sở hữu',
              onTap: () => _showComingSoonToast(context),
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
          body: RefreshIndicator(
            onRefresh: () => context.read<IamFeatureAccessCubit>().load(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: VSpacing.screenMobile,
                vertical: VSpacing.space4,
              ),
              children: [
                if (showReadinessSkeleton) ...[
                  const VSkeleton(
                    key: Key('iam_readiness_hub_banner_skeleton'),
                    width: double.infinity,
                    height: 148,
                    borderRadius: VRadius.card,
                  ),
                  const VGap.sm(),
                ] else if (readinessBanner != null) ...[
                  VCard(
                    key: const Key('iam_readiness_hub_banner'),
                    backgroundColor: readinessBanner.tone == IamReadinessHubBannerTone.success
                        ? colors.successBg
                        : colors.warningBg,
                    padding: const EdgeInsets.all(VSpacing.space4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        VText(
                          readinessBanner.eyebrow,
                          variant: VTextVariant.bodySmall,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: readinessBanner.tone == IamReadinessHubBannerTone.success
                                ? colors.success
                                : colors.warning,
                          ),
                        ),
                        const VGap.xs(),
                        VText(
                          readinessBanner.title,
                          variant: VTextVariant.headingH4,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                        const VGap.xs(),
                        VText(
                          readinessBanner.body,
                          variant: VTextVariant.bodySmall,
                          color: colors.textSecondary,
                        ),
                        const VGap.sm(),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () => _pushAndReload(context, '/more/readiness'),
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
                ],
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

  void _showComingSoonToast(BuildContext context) {
    VToast.show(
      context,
      title: 'Chức năng làm sau',
      message: '',
      type: VToastType.info,
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
