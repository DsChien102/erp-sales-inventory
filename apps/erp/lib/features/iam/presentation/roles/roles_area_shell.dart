import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/di/injection.dart';

import '../../data/invitation_repository.dart';
import '../../data/member_repository.dart';
import '../../logic/roles_cubit.dart';
import 'views/organization_roles_page.dart';

/// Shell phân khu Vai trò — cung cấp [RolesCubit] và bố cục 2 cột web.
class RolesAreaShell extends StatelessWidget {
  const RolesAreaShell({
    super.key,
    required this.child,
    this.selectedId,
    this.invitations,
    this.members,
    this.cubit,
  });

  final Widget child;
  final String? selectedId;
  final InvitationRepository? invitations;
  final MemberRepository? members;
  final RolesCubit? cubit;

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
      create: (_) => RolesCubit(
        invitations: invitations ?? getIt<InvitationRepository>(),
        members: members ?? getIt<MemberRepository>(),
      )..load(),
      child: Builder(
        builder: (context) {
          final cubitInstance = context.read<RolesCubit>();
          return _buildLayout(context, cubitInstance);
        },
      ),
    );
  }

  Widget _buildLayout(BuildContext context, RolesCubit cubitInstance) {
    return VListDetailLayout(
      list: OrganizationRolesPage(
        cubit: cubitInstance,
        selectedId: selectedId,
      ),
      detail: child,
    );
  }
}
