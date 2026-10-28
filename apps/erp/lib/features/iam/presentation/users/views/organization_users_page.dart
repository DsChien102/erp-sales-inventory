import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/core/iam/iam_codes.dart';

import '../../../data/invitation_repository.dart';
import '../../../data/member_repository.dart';
import '../../shared/iam_load_status.dart';
import '../bloc/organization_users_cubit.dart';
import '../bloc/organization_users_state.dart';
import '../models/user_ui_model.dart';
import '../widgets/organization_users_body.dart';
import 'organization_invite_member_page.dart';

/// Trang Danh sách người dùng & Lời mời — composition root for [OrganizationUsersCubit].
class OrganizationUsersPage extends StatelessWidget {
  const OrganizationUsersPage({
    super.key,
    this.members,
    this.invitations,
    this.cubit,
    this.canInvite = true,
  });

  final MemberRepository? members;
  final InvitationRepository? invitations;
  final OrganizationUsersCubit? cubit;
  final bool canInvite;

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: _OrganizationUsersView(canInvite: canInvite),
      );
    }
    assert(
      members != null && invitations != null,
      'OrganizationUsersPage requires members + invitations or cubit',
    );
    return BlocProvider(
      create: (_) => OrganizationUsersCubit(
        members: members!,
        invitations: invitations!,
      )..loadInitial(),
      child: _OrganizationUsersView(canInvite: canInvite),
    );
  }
}

class _OrganizationUsersView extends StatelessWidget {
  const _OrganizationUsersView({required this.canInvite});

  final bool canInvite;

  String _subtitle(OrganizationUsersState state) {
    final isMember = state.activeTab == OrganizationUsersTab.members;
    final status = isMember ? state.memberStatus : state.invitationStatus;
    final failure = isMember ? state.memberFailure : state.invitationFailure;
    final items = isMember ? state.members : state.invitations;
    final search = isMember ? state.memberSearch : state.invitationSearch;
    final filter = isMember ? state.memberFilter : state.invitationFilter;
    final isFiltered = search.trim().isNotEmpty || filter != null;

    if (status == IamLoadStatus.failure) {
      if (failure?.code == IamBlockedCodes.permissionDenied) {
        return 'Chưa cấp quyền';
      }
      return 'Không tải được';
    }
    if (status == IamLoadStatus.loading || status == IamLoadStatus.initial) {
      return isMember ? 'Đang tải thành viên' : 'Đang tải lời mời';
    }
    if (isFiltered && items.isEmpty) return '0 kết quả';
    return isMember ? '${items.length} thành viên' : '${items.length} lời mời';
  }

  Future<void> _navigateInvite(BuildContext context) async {
    dynamic result;
    try {
      result = await context.push('/more/users/invite');
    } catch (_) {
      if (context.mounted) {
        result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const OrganizationInviteMemberPage(),
          ),
        );
      }
    }
    if (result == true && context.mounted) {
      await context.read<OrganizationUsersCubit>().loadInvitations(reset: true);
    }
  }

  Future<void> _openMember(BuildContext context, MemberUiModel member) async {
    try {
      await context.push('/more/users/members/${member.id}');
      // A lifecycle action (suspend / reactivate / remove) inside the detail
      // page mutates member status; refresh on return so the list badge never
      // shows a stale value.
      if (context.mounted) {
        await context.read<OrganizationUsersCubit>().loadMembers(reset: true);
      }
    } catch (_) {
      // Navigator fallback omitted — production uses go_router paths.
    }
  }

  Future<void> _openInvitation(
    BuildContext context,
    InvitationUiModel invitation,
  ) async {
    dynamic result;
    try {
      result = await context.push(
        '/more/users/invitations/${invitation.id}',
      );
    } catch (_) {
      result = null;
    }
    if (result == true && context.mounted) {
      VToast.show(
        context,
        title: 'Đã thu hồi lời mời.',
        message: '',
        type: VToastType.success,
      );
      await context.read<OrganizationUsersCubit>().loadInvitations(reset: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrganizationUsersCubit, OrganizationUsersState>(
      builder: (context, state) {
        return VPageScaffold(
          title: 'Người dùng',
          subtitle: _subtitle(state),
          actions: canInvite
              ? [
                  IconButton(
                    key: const Key('users_invite'),
                    tooltip: 'Mời thành viên',
                    icon: VIcon(
                      icon: VIcons.add,
                      color: context.vColors.textPrimary,
                    ),
                    onPressed: () => _navigateInvite(context),
                  ),
                ]
              : null,
          body: OrganizationUsersBody(
            canInvite: canInvite,
            onMemberTap: (m) => _openMember(context, m),
            onInvitationTap: (i) => _openInvitation(context, i),
            onInviteTap: () => _navigateInvite(context),
          ),
        );
      },
    );
  }
}
