import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_presentation/presentation.dart';

import '../../../tenant_context/presentation/bloc/tenant_context_cubit.dart';
import '../../../tenant_context/presentation/bloc/tenant_context_state.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  Future<void> _openSelector(BuildContext context) async {
    final cubit = context.read<TenantContextCubit>();
    if (cubit.state.tenants.isEmpty && !cubit.state.tenantsLoading) {
      await cubit.loadAccessibleTenants();
    }
    if (!context.mounted) return;

    final state = cubit.state;
    await showSelectOrganizationBottomSheet(
      context: context,
      organizations: state.tenants,
      onConfirmSwitch: (org) async {
        final ok = await cubit.switchTo(org.id);
        if (!ok) {
          final message = cubit.state.errorMessage;
          if (message != null && message.isNotEmpty) {
            throw Exception(message);
          }
        }
        return ok;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return BlocBuilder<TenantContextCubit, TenantContextState>(
      builder: (context, state) {
        final branchName =
            state.branchDisplayName ??
            (state.isBlocked ? 'Chọn tổ chức' : 'Đang tải…');

        return Container(
          color: dynamicColors.primary,
          child: SafeArea(
            bottom: false,
            child: VHomeHeader(
              userName: state.userDisplayName,
              branchName: branchName,
              hasNotification: true,
              onBranchTap: () => _openSelector(context),
              onNotificationTap: () {},
              searchBar: const VSearchBar(
                variant: VSearchBarVariant.header,
                hintText: 'Tìm đơn hàng, sản phẩm, khách hàng...',
                readOnly: true,
              ),
            ),
          ),
        );
      },
    );
  }
}
