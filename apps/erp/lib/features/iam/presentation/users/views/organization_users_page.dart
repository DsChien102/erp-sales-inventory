import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/config/wide_layout.dart';
import 'package:erp/core/iam/iam_codes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
        child: _OrganizationUsersView(
          canInvite: canInvite,
        ),
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
      child: _OrganizationUsersView(
        canInvite: canInvite,
      ),
    );
  }
}

class _OrganizationUsersView extends StatelessWidget {
  const _OrganizationUsersView({
    required this.canInvite,
  });

  final bool canInvite;

  String _subtitle(OrganizationUsersState state) {
    final isMember = state.activeTab == OrganizationUsersTab.members;
    final status = isMember ? state.memberStatus : state.invitationStatus;
    final failure = isMember ? state.memberFailure : state.invitationFailure;
    final items = isMember ? state.members : state.invitations;
    final isFiltered = isMember ? state.isMemberFiltered : state.isInvitationFiltered;

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
      final cubit = context.read<OrganizationUsersCubit>();
      cubit.selectTab(OrganizationUsersTab.invitations);
      await cubit.loadInvitations(reset: true);
    }
  }

  Future<void> _openMember(BuildContext context, MemberUiModel member) async {
    final path = '/more/users/members/${member.id}';
    if (isWideLayout(context)) {
      context.go(path);
      return;
    }
    try {
      await context.push(path);
    } catch (_) {
      // Navigator fallback omitted — production uses go_router paths.
    }
  }

  Future<void> _openInvitation(
    BuildContext context,
    InvitationUiModel invitation,
  ) async {
    final path = '/more/users/invitations/${invitation.id}';
    if (isWideLayout(context)) {
      context.go(path);
      return;
    }
    try {
      await context.push(path);
    } catch (_) {
      // Navigator fallback omitted — production uses go_router paths.
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = isWideLayout(context);
    final colors = context.vColors;

    return BlocConsumer<OrganizationUsersCubit, OrganizationUsersState>(
      listenWhen: (p, c) => p.loadMoreFailure != c.loadMoreFailure && c.loadMoreFailure != null,
      listener: (context, state) {
        final failure = state.loadMoreFailure;
        if (failure == null) return;
        VToast.show(
          context,
          title: 'Không tải thêm được',
          message: 'Không tải thêm được. ${failure.message}',
          type: VToastType.danger,
        );
        context.read<OrganizationUsersCubit>().clearLoadMoreFailure();
      },
      builder: (context, state) {
        final isMember = state.activeTab == OrganizationUsersTab.members;
        final status = isMember ? state.memberStatus : state.invitationStatus;
        final items = isMember ? state.members : state.invitations;
        final isLoading = status == IamLoadStatus.loading || status == IamLoadStatus.initial;
        final isFiltered = isMember ? state.isMemberFiltered : state.isInvitationFiltered;
        final hasBottomBar =
            !wide &&
            canInvite &&
            status != IamLoadStatus.failure &&
            (isLoading || items.isNotEmpty || isFiltered);

        return VPageScaffold(
          title: 'Người dùng',
          subtitle: _subtitle(state),
          contentMaxWidth: wide
              ? VPageScaffold.fullWidth
              : VPageScaffold.defaultContentMaxWidth,
          actions: wide && canInvite
              ? [
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: VButton(
                      key: const Key('users_invite'),
                      label: 'Mời thành viên',
                      onPressed: () => _navigateInvite(context),
                    ),
                  ),
                ]
              : null,
          body: ColoredBox(
            color: colors.surfaceAlt,
            child: OrganizationUsersBody(
              canInvite: canInvite,
              onMemberTap: (m) => _openMember(context, m),
              onInvitationTap: (i) => _openInvitation(context, i),
              onInviteTap: () => _navigateInvite(context),
            ),
          ),
          bottomBar: hasBottomBar
              ? Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border(
                      top: BorderSide(color: colors.borderDefault),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: VButton(
                      key: const Key('users_invite'),
                      label: 'Mời thành viên',
                      fullWidth: true,
                      onPressed: () => _navigateInvite(context),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}
