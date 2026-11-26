import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:c45_design_system/design_system.dart';

import '../../../../../core/config/wide_layout.dart';
import '../../../../../core/di/injection.dart';
import '../../../data/invitation_repository.dart';
import '../../../data/member_repository.dart';
import '../../../logic/iam_load_status.dart';
import '../../../logic/role_ui_model.dart';
import '../../../logic/roles_cubit.dart';
import '../../../logic/roles_state.dart';
import '../widgets/roles_narrow.dart';
import '../widgets/roles_wide.dart';
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
    if (isWideLayout(context)) {
      context.go('/more/roles/${role.id}', extra: role);
      return;
    }
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
    final wide = isWideLayout(context);

    return BlocBuilder<RolesCubit, RolesState>(
      builder: (context, state) {
        final loading =
            state.status == IamLoadStatus.loading ||
            state.status == IamLoadStatus.initial;
        final failed = state.status == IamLoadStatus.failure;
        final roles = state.roles;

        final subtitle = failed
            ? 'Không tải được'
            : loading
                ? 'Đang tải vai trò'
                : '${roles.length} vai trò hệ thống';

        return VPageScaffold(
          title: 'Vai trò',
          subtitle: subtitle,
          contentMaxWidth: VPageScaffold.fullWidth,
          body: wide
              ? RolesWide(
                  loading: loading,
                  failed: failed,
                  roles: roles,
                  onRetry: () => context.read<RolesCubit>().load(),
                  onRoleTap: (role) => _openDetail(context, role),
                )
              : RolesNarrow(
                  loading: loading,
                  failed: failed,
                  roles: roles,
                  onRetry: () => context.read<RolesCubit>().load(),
                  onRoleTap: (role) => _openDetail(context, role),
                ),
        );
      },
    );
  }
}
