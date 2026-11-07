import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/sales/logic/sales_transaction_result_state.dart';

class SalesResultCustomerCard extends StatelessWidget {
  const SalesResultCustomerCard({
    super.key,
    required this.state,
  });

  final SalesTransactionResultState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return VCard(
      padding: const EdgeInsets.all(VSpacing.space3),
      child: Row(
        children: [
          VIconBox(
            icon: VIcons.person,
            size: 40,
            iconSize: 20,
            backgroundColor: colors.surfaceAlt,
            iconColor: colors.textPrimary,
            borderRadius: VRadius.card,
          ),
          const VGap.horizontalSm(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(
                  state.order?.customer?.displayName ?? 'Khách lẻ',
                  variant: VTextVariant.bodyDefault,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const VGap.xs(),
                VText(
                  state.order?.customer?.phoneNumber ?? 'Không có số điện thoại',
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
