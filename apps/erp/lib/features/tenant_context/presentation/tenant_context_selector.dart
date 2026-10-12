import 'package:erp/features/iam/presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/session/session_controller.dart';

Future<void> openTenantContextSelector(BuildContext context) async {
  final cubit = context.read<SessionController>();
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
