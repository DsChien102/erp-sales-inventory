import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import '../models/sales_order/sales_checkout_vm.dart';
import 'package:erp/core/formatting/money_formatter.dart';
/// Customer header for the checkout screen: name, phone, and the customer's
/// existing debt ("Nợ cũ"). The debt badge is hidden for walk-in customers.
class SalesCheckoutSummaryCard extends StatelessWidget {
  const SalesCheckoutSummaryCard({
    super.key,
    required this.vm,
  });

  final SalesCheckoutVm vm;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return VCard(
      padding: const EdgeInsets.all(VSpacing.space3),
      child: Row(
        children: [
          const VGap(VSpacing.space1, axis: Axis.horizontal),
          VIcon(
            icon: VIcons.person,
            size: 20,
            color: colors.textSecondary,
          ),
          const VGap.horizontalCozy(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(
                  vm.customerName ?? 'Khách lẻ',
                  variant: VTextVariant.bodyDefault,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const VGap.xs(),
                VText(
                  vm.customerPhone ??
                      (vm.isWalkIn ? 'Không bắt buộc thông tin' : 'Chưa có số điện thoại'),
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
          if (!vm.isWalkIn) ...[
            const VGap.horizontalSm(),
            VBadge(
              key: const Key('txt_sg05_customer_debt'),
              label: 'Nợ cũ ${MoneyFormatter.formatMinor(vm.customerDebtMinor)}',
              tone: VComponentTone.neutral,
            ),
          ],
        ],
      ),
    );
  }
}
