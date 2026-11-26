import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erp/core/di/injection.dart';

import '../../data/invitation_repository.dart';
import '../../data/member_repository.dart';
import '../../logic/roles_cubit.dart';

/// Shell phân khu Vai trò — cung cấp [RolesCubit] dùng chung giữa danh sách và chi tiết.
class RolesAreaShell extends StatelessWidget {
  const RolesAreaShell({
    super.key,
    required this.child,
    this.invitations,
    this.members,
    this.cubit,
  });

  final Widget child;
  final InvitationRepository? invitations;
  final MemberRepository? members;
  final RolesCubit? cubit;

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: child,
      );
    }
    return BlocProvider(
      create: (_) => RolesCubit(
        invitations: invitations ?? getIt<InvitationRepository>(),
        members: members ?? getIt<MemberRepository>(),
      )..load(),
      child: child,
    );
  }
}
