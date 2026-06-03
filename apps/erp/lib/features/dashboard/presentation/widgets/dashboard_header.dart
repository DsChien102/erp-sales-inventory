import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final dynamicColors = context.vColors;

    return Container(
      color: dynamicColors.primary,
      child: SafeArea(
        bottom: false,
        child: VHomeHeader(
          userName: 'Lan',
          branchName: 'Thú y Minh Phát · CN Biên Hoà',
          hasNotification: true,
          onBranchTap: () {},
          onNotificationTap: () {},
          searchBar: const VSearchBar(
            variant: VSearchBarVariant.header,
            hintText: 'Tìm đơn hàng, sản phẩm, khách hàng...',
            readOnly: true,
          ),
        ),
      ),
    );
  }
}
