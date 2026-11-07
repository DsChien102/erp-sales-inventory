import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../models/return_exchange_order/sales_return_exchange_settlement_vm.dart';
import 'package:erp/core/formatting/money_formatter.dart';

/// SG-12 — VBottomSheet Xác nhận Quyết toán đổi/trả (read-only plan).
Future<bool?> showSalesReturnConfirmSettlementSheet(
  BuildContext context, {
  required SalesReturnExchangeSettlementVm vm,
}) {
  return showVBottomSheet<bool>(
    context: context,
    semanticLabel: 'Xác nhận đổi/trả',
    child: SalesReturnConfirmSettlementSheet(vm: vm),
  );
}

/// Builds confirmation message from authoritative settlement plan amounts.
String buildReturnConfirmationMessage(SalesReturnExchangeSettlementVm vm) {
  final refund = vm.storeRefundMinor;
  final collect = vm.customerCollectMinor;
  final receivableCreate = vm.receivableCreateMinor;
  final receivableReverse = vm.receivableReverseMinor;

  if (refund <= 0 && collect <= 0 && receivableCreate <= 0 && receivableReverse <= 0) {
    return 'Xác nhận đổi/trả hàng không phát sinh chênh lệch.';
  }

  final parts = <String>[];
  if (collect > 0) {
    parts.add('Thu thêm ${MoneyFormatter.formatMinor(collect)} từ khách');
  }
  if (refund > 0) {
    parts.add('Hoàn ${MoneyFormatter.formatMinor(refund)} cho khách');
  }
  if (receivableCreate > 0) {
    parts.add(
      'ghi nhận công nợ ${MoneyFormatter.formatMinor(receivableCreate)}',
    );
  }
  if (receivableReverse > 0) {
    parts.add(
      'ghi giảm công nợ ${MoneyFormatter.formatMinor(receivableReverse)}',
    );
  }

  if (parts.length == 1) {
    return '${parts.single}.';
  }
  final head = parts.sublist(0, parts.length - 1).join(', ');
  return '$head và ${parts.last}.';
}

class SalesReturnConfirmSettlementSheet extends StatelessWidget {
  const SalesReturnConfirmSettlementSheet({
    super.key,
    required this.vm,
  });

  final SalesReturnExchangeSettlementVm vm;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final message = buildReturnConfirmationMessage(vm);

    return VPagePadding(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VText(
            'Xác nhận đổi/trả?',
            variant: VTextVariant.headingH3,
            color: colors.textPrimary,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const VGap.xs(),
          VText(
            message,
            variant: VTextVariant.bodyDefault,
            color: colors.textSecondary,
          ),
          const VGap.lg(),
          VButton(
            key: const Key('btn_confirm_settlement_submit'),
            label: 'Xác nhận đổi/trả',
            variant: VButtonVariant.primary,
            size: VButtonSize.large,
            fullWidth: true,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const VGap.sm(),
          VButton(
            key: const Key('btn_confirm_settlement_back'),
            label: 'Quay lại',
            variant: VButtonVariant.secondary,
            size: VButtonSize.large,
            fullWidth: true,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }
}
