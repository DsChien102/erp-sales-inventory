import 'package:erp/core/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/invitation_repository.dart';
import '../../data/member_repository.dart';
import 'bloc/organization_users_cubit.dart';

/// Shell phân khu Người dùng — cung cấp [OrganizationUsersCubit] dùng chung giữa danh sách và chi tiết.
class UsersAreaShell extends StatelessWidget {
  const UsersAreaShell({
    super.key,
    required this.child,
    this.members,
    this.invitations,
    this.cubit,
  });

  final Widget child;
  final MemberRepository? members;
  final InvitationRepository? invitations;
  final OrganizationUsersCubit? cubit;

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: child,
      );
    }
    return BlocProvider(
      create: (_) => OrganizationUsersCubit(
        members: members ?? getIt<MemberRepository>(),
        invitations: invitations ?? getIt<InvitationRepository>(),
      )..loadInitial(),
      child: child,
    );
  }
}
