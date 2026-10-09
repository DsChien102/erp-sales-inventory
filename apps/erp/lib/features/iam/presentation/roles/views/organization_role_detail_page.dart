import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../../../../core/di/injection.dart';
import '../../../data/invitation_repository.dart';
import '../../../data/member_repository.dart';
import '../../../logic/iam_load_status.dart';
import '../../../logic/role_ui_model.dart';
import '../../../logic/roles_cubit.dart';
import '../../../logic/roles_state.dart';

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
      return _RoleDetailBody(role: known);
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
        if (role != null) return _RoleDetailBody(role: role);
        if (state.status == IamLoadStatus.failure) {
          return const VPageScaffold(
            title: 'Chi tiết vai trò',
            body: Center(child: Text(rolesLoadErrorMessage)),
          );
        }
        return const VPageScaffold(
          title: 'Chi tiết vai trò',
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

class _RoleDetailBody extends StatelessWidget {
  const _RoleDetailBody({required this.role});

  final RoleUiModel role;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return VPageScaffold(
      title: 'Chi tiết vai trò',
      body: ListView(
        padding: const EdgeInsets.all(VSpacing.screenMobile),
        children: [
          VCard(
            padding: const EdgeInsets.all(VSpacing.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(
                  role.title,
                  variant: VTextVariant.headingH4,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const VGap.xs(),
                VText(
                  role.description,
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
                const VGap.md(),
                VText(
                  'Vai trò hệ thống · Chỉ đọc',
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
          const VGap.md(),
          VText(
            'Thành viên đang giữ vai trò',
            variant: VTextVariant.headingH4,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const VGap.sm(),
          if (role.memberNames.isEmpty)
            VText(
              'Chưa có thành viên đang giữ vai trò này.',
              variant: VTextVariant.bodySmall,
              color: colors.textSecondary,
            )
          else
            ...role.memberNames.map(
              (name) => Padding(
                padding: const EdgeInsets.only(bottom: VSpacing.space2),
                child: VText(name, variant: VTextVariant.bodyDefault),
              ),
            ),
        ],
      ),
    );
  }
}
