import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/di/injection.dart';

import '../../data/invitation_repository.dart';
import '../../data/member_repository.dart';
import 'bloc/organization_users_cubit.dart';
import 'views/organization_users_page.dart';

/// Shell phân khu Người dùng — cung cấp [OrganizationUsersCubit] và bố cục 2 cột web.
class UsersAreaShell extends StatelessWidget {
  const UsersAreaShell({
    super.key,
    required this.child,
    this.selectedId,
    this.canInvite = false,
    this.members,
    this.invitations,
    this.cubit,
  });

  final Widget child;
  final String? selectedId;
  final bool canInvite;
  final MemberRepository? members;
  final InvitationRepository? invitations;
  final OrganizationUsersCubit? cubit;

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: Builder(
          builder: (context) => _buildLayout(context, cubit!),
        ),
      );
    }
    return BlocProvider(
      create: (_) => OrganizationUsersCubit(
        members: members ?? getIt<MemberRepository>(),
        invitations: invitations ?? getIt<InvitationRepository>(),
      )..loadInitial(),
      child: Builder(
        builder: (context) {
          final cubitInstance = context.read<OrganizationUsersCubit>();
          return _buildLayout(context, cubitInstance);
        },
      ),
    );
  }

  Widget _buildLayout(BuildContext context, OrganizationUsersCubit cubitInstance) {
    return VListDetailLayout(
      list: OrganizationUsersPage(
        cubit: cubitInstance,
        canInvite: canInvite,
        selectedId: selectedId,
      ),
      detail: child,
    );
  }
}
