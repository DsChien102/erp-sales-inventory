import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../../../../core/di/injection.dart';
import '../../../data/invitation_repository.dart';
import '../../../data/member_repository.dart';
import '../../../logic/iam_load_status.dart';
import '../../../logic/role_ui_model.dart';
import '../../../logic/roles_cubit.dart';
import '../../../logic/roles_state.dart';
import 'organization_role_detail_page.dart';

/// Danh mục vai trò hệ thống (US-07.1).
class OrganizationRolesPage extends StatelessWidget {
  const OrganizationRolesPage({
    super.key,
    this.invitations,
    this.members,
    this.cubit,
  });

  final InvitationRepository? invitations;
  final MemberRepository? members;
  final RolesCubit? cubit;

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: const _OrganizationRolesView(),
      );
    }
    return BlocProvider(
      create: (_) => RolesCubit(
        invitations: invitations ?? getIt<InvitationRepository>(),
        members: members ?? getIt<MemberRepository>(),
      )..load(),
      child: const _OrganizationRolesView(),
    );
  }
}

class _OrganizationRolesView extends StatelessWidget {
  const _OrganizationRolesView();

  Future<void> _openDetail(BuildContext context, RoleUiModel role) async {
    try {
      await context.push('/more/roles/${role.id}', extra: role);
    } catch (_) {
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OrganizationRoleDetailPage(role: role),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RolesCubit, RolesState>(
      builder: (context, state) {
        final colors = context.vColors;
        final failed = state.status == IamLoadStatus.failure;
        final roles = state.roles;

        return VPageScaffold(
          title: 'Vai trò',
          subtitle: failed ? 'Không tải được' : '${roles.length} vai trò hệ thống',
          body: failed
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: VSpacing.screenMobile),
                    child: VCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: VSpacing.space5,
                        vertical: VSpacing.space6,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: colors.dangerBg,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: VIcon(
                                icon: VIcons.close,
                                size: 28,
                                color: colors.danger,
                              ),
                            ),
                          ),
                          const VGap.md(),
                          VText(
                            'Không thể tải danh sách vai trò',
                            variant: VTextVariant.headingH3,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: colors.danger,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const VGap.xs(),
                          VText(
                            'Dịch vụ phân quyền đang tạm thời không khả dụng. Vui lòng thử lại sau.',
                            variant: VTextVariant.bodyDefault,
                            color: colors.textSecondary,
                            textAlign: TextAlign.center,
                          ),
                          const VGap.md(),
                          GestureDetector(
                            onTap: () => context.read<RolesCubit>().load(),
                            child: VText(
                              'Thử lại',
                              variant: VTextVariant.bodyDefault,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: colors.danger,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(VSpacing.screenMobile),
                  children: [
                    VText(
                      'Vai trò hệ thống',
                      variant: VTextVariant.headingH4,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const VGap.xs(),
                    VText(
                      'Vai trò vận hành không thay đổi tư cách Chủ sở hữu.',
                      variant: VTextVariant.bodySmall,
                      color: colors.textSecondary,
                    ),
                    const VGap.md(),
                    ...roles.map(
                      (role) => Padding(
                        padding: const EdgeInsets.only(bottom: VSpacing.space3),
                        child: InkWell(
                          onTap: () => _openDetail(context, role),
                          borderRadius: BorderRadius.circular(VRadius.card),
                          child: Container(
                            padding: const EdgeInsets.all(VSpacing.space4),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              border: Border.all(color: colors.borderDefault),
                              borderRadius: BorderRadius.circular(VRadius.card),
                            ),
                            child: Row(
                              children: [
                                VIcon(
                                  icon: VIcons.person,
                                  size: 24,
                                  color: colors.textPrimary,
                                ),
                                const VGap.horizontalMd(),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      VText(
                                        role.title,
                                        variant: VTextVariant.bodyDefault,
                                        style: const TextStyle(fontWeight: FontWeight.w700),
                                      ),
                                      const VGap.xs(),
                                      VText(
                                        role.description,
                                        variant: VTextVariant.bodySmall,
                                        color: colors.textSecondary,
                                      ),
                                    ],
                                  ),
                                ),
                                if (role.isCurrent)
                                  const VBadge(
                                    label: 'Đang dùng',
                                    tone: VComponentTone.success,
                                    variant: VBadgeVariant.soft,
                                    isSmall: true,
                                  )
                                else
                                  VIcon(
                                    icon: VIcons.chevronRight,
                                    size: 20,
                                    color: colors.textSecondary,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
