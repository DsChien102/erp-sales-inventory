import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_infrastructure/infrastructure.dart';
import 'package:erp/features/iam/presentation.dart';

import '../../../../core/di/injection.dart';
import 'bloc/tenant_context_cubit.dart';

/// Syncs [IamSession] (router/navigation permission checks) from switch/bootstrap.
void applyTenantContextPermissions(TenantContextDto context) {
  if (!getIt.isRegistered<IamSession>()) return;
  final session = getIt<IamSession>();
  final userId = session.userId;
  final tenantId = context.tenantId;
  if (userId == null || userId.isEmpty || tenantId == null || tenantId.isEmpty) {
    return;
  }
  session.apply(
    PrincipalAccessDto(
      userId: userId,
      tenantId: tenantId,
      role: context.roleLabel ?? session.role ?? '',
      isOwner: context.isOwner,
      permissions: context.permissions,
    ),
  );
}

Future<void> openTenantContextSelector(BuildContext context) async {
  final cubit = context.read<TenantContextCubit>();
  if (cubit.state.tenants.isEmpty &&
      !cubit.state.tenantsLoading &&
      cubit.state.selectorFailure == null) {
    await cubit.loadAccessibleTenants();
  }
  if (!context.mounted) return;

  await showSelectOrganizationBottomSheet(
    context: context,
    organizations: cubit.state.tenants,
    emptyStateType: cubit.selectorEmptyStateType,
    suspendedOrgName: cubit.state.suspendedOrgName,
    onRetryLoad: cubit.retryLoadAccessibleTenants,
    onEmptyAction: () => cubit.loadAccessibleTenants(),
    onConfirmSwitch: (org) async {
      final ok = await cubit.switchTo(org.id);
      if (!ok) {
        final message = cubit.state.switchFailure?.message;
        if (message != null && message.isNotEmpty) {
          throw Exception(message);
        }
      }
      return ok;
    },
  );
  cubit.consumeOpenSelectorRequest();
}
