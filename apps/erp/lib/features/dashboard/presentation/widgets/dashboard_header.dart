import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_dashboard_presentation/presentation.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../../tenant_context/presentation/bloc/tenant_context_cubit.dart';
import '../../../tenant_context/presentation/bloc/tenant_context_state.dart';
import '../../../tenant_context/presentation/tenant_context_selector.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

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
            child: HomeHeader(
              branchName: branchName,
              hasNotification: true,
              onBranchTap: () => openTenantContextSelector(context),
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
