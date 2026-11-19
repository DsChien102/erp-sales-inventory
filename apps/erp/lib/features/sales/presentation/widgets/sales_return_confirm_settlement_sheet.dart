import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

import 'package:erp/features/receivable/logic/receivable_format.dart';
import 'package:erp/features/sales/logic/return_settlement_preview.dart';

import '../models/return_exchange_order/sales_return_exchange_settlement_vm.dart';
import 'package:erp/core/formatting/money_formatter.dart';

/// SG-12 — VBottomSheet Xác nhận Quyết toán đổi/trả (read-only plan).
Future<bool?> showSalesReturnConfirmSettlementSheet(
  BuildContext context, {
  required SalesReturnExchangeSettlementVm vm,
  List<String> settlementLines = const [],
}) {
  return showVBottomSheet<bool>(
    context: context,
    semanticLabel: 'Xác nhận đổi/trả',
    child: SalesReturnConfirmSettlementSheet(vm: vm, settlementLines: settlementLines),
  );
}

/// Các dòng tóm tắt cách chia tiền khi khách được hưởng (SG-13).
List<String> buildEntitledSettlementLines(ReturnSettlementPreview preview) => [
  if (preview.reduceOwnDebtMinor > 0)
    'Giảm nợ đơn này ${formatVnd(preview.reduceOwnDebtMinor)}',
  for (final o in preview.offsets)
    if (o.amountMinor > 0) 'Cấn trừ ${formatVnd(o.amountMinor)} vào đơn ${o.orderCode}',
  if (preview.refundMinor > 0) 'Hoàn ${formatVnd(preview.refundMinor)} cho khách',
];

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
    this.settlementLines = const [],
  });

  final SalesReturnExchangeSettlementVm vm;

  /// Có dòng thì hiện danh sách gạch đầu dòng thay cho phần tóm tắt cũ.
  final List<String> settlementLines;

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
          if (settlementLines.isEmpty)
            VText(
              message,
              variant: VTextVariant.bodyDefault,
              color: colors.textSecondary,
            )
          else
            Column(
              key: const Key('wgt_confirm_settlement_lines'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final line in settlementLines)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('•  ', style: TextStyle(color: colors.textPrimary)),
                      Expanded(
                        child: Text(
                          line,
                          style: VTypography.bodyDefault.copyWith(color: colors.textPrimary),
                        ),
                      ),
                    ],
                  ),
              ],
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
