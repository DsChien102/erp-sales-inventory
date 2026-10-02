import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/iam_load_status.dart';
import '../bloc/organization_users_cubit.dart';
import '../bloc/organization_users_state.dart';
import '../models/user_ui_model.dart';
import '../widgets/organization_users_body.dart';

/// Danh sách thành viên tổ chức trên Platform Admin (chỉ đọc Membership thật).
/// Lời mời thành viên thông thường thuộc Tenant App — không có điểm vào tại đây.
class OrganizationUsersPage extends StatelessWidget {
  const OrganizationUsersPage({
    super.key,
    this.iamModule,
    this.executionContext,
    this.cubit,
  });

  final IIamModule? iamModule;
  final IExecutionContext? executionContext;
  final OrganizationUsersCubit? cubit;

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: const _OrganizationUsersView(),
      );
    }
    assert(
      iamModule != null && executionContext != null,
      'OrganizationUsersPage requires iamModule + executionContext or cubit',
    );
    return BlocProvider(
      create: (_) => OrganizationUsersCubit(
        iamModule: iamModule!,
        executionContext: executionContext!,
      )..loadMembers(reset: true),
      child: const _OrganizationUsersView(),
    );
  }
}

class _OrganizationUsersView extends StatelessWidget {
  const _OrganizationUsersView();

  String _subtitle(OrganizationUsersState state) {
    final status = state.memberStatus;
    final failure = state.memberFailure;
    final items = state.members;
    final isFiltered = state.memberSearch.trim().isNotEmpty || state.memberFilter != null;

    if (status == IamLoadStatus.failure) {
      if (failure?.code == IamBlockedCodes.permissionDenied) {
        return 'Chưa cấp quyền';
      }
      return 'Không tải được';
    }
    if (status == IamLoadStatus.loading || status == IamLoadStatus.initial) {
      return 'Đang tải thành viên';
    }
    if (isFiltered && items.isEmpty) return '0 kết quả';
    return '${items.length} thành viên';
  }

  Future<void> _openMember(BuildContext context, MemberUiModel member) async {
    try {
      await context.push('/more/users/members/${member.id}');
      if (context.mounted) {
        await context.read<OrganizationUsersCubit>().loadMembers(reset: true);
      }
    } catch (_) {
      // Navigator fallback omitted — production uses go_router paths.
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrganizationUsersCubit, OrganizationUsersState>(
      builder: (context, state) {
        return VPageScaffold(
          title: 'Người dùng',
          subtitle: _subtitle(state),
          body: OrganizationUsersBody(
            onMemberTap: (m) => _openMember(context, m),
          ),
        );
      },
    );
  }
}
