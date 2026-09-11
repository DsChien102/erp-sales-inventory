import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:erp/features/catalog/presentation.dart';
import 'package:vet45_design_system/design_system.dart';

class ProductControlCenterStatusBadge extends StatelessWidget {
  const ProductControlCenterStatusBadge({
    super.key,
    required this.fallbackIsSoftDeleted,
  });

  final bool fallbackIsSoftDeleted;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductControlCenterCubit, ProductControlCenterState>(
      builder: (context, state) {
        final isReady =
            state.controlCenter?.readinessSummary.status == ReadinessStatus.readyToSell;
        final isSoftDeleted =
            state.controlCenter?.profile.isSoftDeleted ?? fallbackIsSoftDeleted;

        return Center(
          child: Padding(
            padding: const EdgeInsets.only(right: VSpacing.md),
            child: VBadge(
              label: isSoftDeleted
                  ? 'Đã xóa'
                  : isReady
                  ? 'Sẵn sàng bán'
                  : 'Thiếu dữ liệu',
              status: isSoftDeleted
                  ? VBadgeStatus.locked
                  : isReady
                  ? VBadgeStatus.success
                  : VBadgeStatus.danger,
              isSmall: true,
            ),
          ),
        );
      },
    );
  }
}
