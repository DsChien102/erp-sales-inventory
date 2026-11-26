import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:c45_design_system/design_system.dart';

import '../../../../../core/config/wide_layout.dart';
import '../../../../../core/di/injection.dart';
import '../../../data/invitation_repository.dart';
import '../../../data/member_repository.dart';
import '../../../logic/iam_load_status.dart';
import '../../../logic/role_ui_model.dart';
import '../../../logic/roles_cubit.dart';
import '../../../logic/roles_state.dart';
import '../widgets/role_card.dart';
import '../widgets/role_detail_narrow.dart';
import '../widgets/role_detail_wide.dart';

/// Chi tiết vai trò hệ thống (US-07.1 FR-02).
class OrganizationRoleDetailPage extends StatelessWidget {
  const OrganizationRoleDetailPage({
    super.key,
    this.role,
    this.code,
    this.invitations,
    this.members,
    this.cubit,
  });

  final RoleUiModel? role;
  final String? code;
  final InvitationRepository? invitations;
  final MemberRepository? members;
  final RolesCubit? cubit;

  @override
  Widget build(BuildContext context) {
    final known = role;
    if (known != null) {
      return _RoleDetailScaffold(role: known);
    }
    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: _LoadedRoleDetail(code: code ?? ''),
      );
    }
    return BlocProvider(
      create: (_) => RolesCubit(
        invitations: invitations ?? getIt<InvitationRepository>(),
        members: members ?? getIt<MemberRepository>(),
      )..load(),
      child: _LoadedRoleDetail(code: code ?? ''),
    );
  }
}

class _LoadedRoleDetail extends StatelessWidget {
  const _LoadedRoleDetail({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RolesCubit, RolesState>(
      builder: (context, state) {
        RoleUiModel? role;
        for (final item in state.roles) {
          if (item.id == code) {
            role = item;
            break;
          }
        }
        if (role != null) return _RoleDetailScaffold(role: role);
        if (state.status == IamLoadStatus.failure) {
          return VPageScaffold(
            title: 'Chi tiết vai trò',
            showBackButton: true,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: VSpacing.screenMobile,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: RolesLoadError(
                    onRetry: () => context.read<RolesCubit>().load(),
                  ),
                ),
              ),
            ),
          );
        }
        if (state.status == IamLoadStatus.success) {
          return const VPageScaffold(
            title: 'Chi tiết vai trò',
            showBackButton: true,
            body: Center(child: Text('Không tìm thấy vai trò')),
          );
        }
        return const VPageScaffold(
          title: 'Chi tiết vai trò',
          showBackButton: true,
          body: Center(child: VLoading(size: 40)),
        );
      },
    );
  }
}

class _RoleDetailScaffold extends StatelessWidget {
  const _RoleDetailScaffold({required this.role});

  final RoleUiModel role;

  @override
  Widget build(BuildContext context) {
    final wide = isWideLayout(context);
    return VPageScaffold(
      title: 'Chi tiết vai trò',
      showBackButton: true,
      body: wide ? RoleDetailWide(role: role) : RoleDetailNarrow(role: role),
    );
  }
}
