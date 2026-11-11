import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/core/formatting/money_formatter.dart';
import 'package:erp/features/inventory/logic/goods_receipt/receipt_draft.dart';

void showReceiptLineDetailSheet({
  required BuildContext context,
  required ReceiptLineDraft line,
}) {
  showVAdaptiveSheet(
    context: context,
    child: Builder(
      builder: (context) {
        final gross = (line.paidQuantity * line.unitPriceVnd).round();
        final tierVnd = line.tierPercent != null && line.tierPercent! > 0
            ? (gross * line.tierPercent! / 100).round()
            : 0;
        final purchase = gross - tierVnd;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(VSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                line.product.name,
                style: VTypography.headingH3,
              ),
              const SizedBox(height: VSpacing.space1),
              Text(
                'Mã: ${line.product.code} · ĐVT: ${line.unit.name}',
                style: VTypography.bodySmall,
              ),
              const SizedBox(height: VSpacing.space4),
              VCard(
                child: Column(
                  children: [
                    VKeyValueRow(
                      label: 'Đơn giá mua',
                      value: '${MoneyFormatter.formatMinorPlain(line.unitPriceVnd)} đ',
                    ),
                    VKeyValueRow(
                      label: 'SL thanh toán',
                      value: '${line.paidQuantity} ${line.unit.name}',
                    ),
                    if (line.freeQty > 0)
                      VKeyValueRow(
                        label: 'SL tặng',
                        value: '${line.freeQty} ${line.unit.name}',
                      ),
                    VKeyValueRow(
                      label: 'Tổng nhận',
                      value: '${line.totalQuantity} ${line.unit.name}',
                    ),
                    if (tierVnd > 0)
                      VKeyValueRow(
                        label: 'Giảm bậc (${line.tierPercent}%)',
                        value: '-${MoneyFormatter.formatMinorPlain(tierVnd)} đ',
                      ),
                    VKeyValueRow(
                      label: 'Thành tiền mua',
                      value: '${MoneyFormatter.formatMinorPlain(purchase)} đ',
                      emphasized: true,
                    ),
                  ],
                ),
              ),
              if (line.lots.isNotEmpty) ...[
                const SizedBox(height: VSpacing.space4),
                Text('Chi tiết lô (${line.lots.length})', style: VTypography.headingH4),
                const SizedBox(height: VSpacing.space1),
                for (final lot in line.lots) ...[
                  VCard(
                    child: Column(
                      children: [
                        VKeyValueRow(
                          label: 'Mã lô',
                          value: lot.code.isEmpty ? '(Không mã lô)' : lot.code,
                        ),
                        VKeyValueRow(
                          label: 'Số lượng',
                          value: '${lot.quantity} ${line.unit.name}',
                        ),
                        if (lot.expiryText.isNotEmpty)
                          VKeyValueRow(
                            label: 'Hạn sử dụng',
                            value: lot.expiryText,
                          ),
                        if (lot.manufactureText.isNotEmpty)
                          VKeyValueRow(
                            label: 'Ngày sản xuất',
                            value: lot.manufactureText,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: VSpacing.space1),
                ],
              ],
              const SizedBox(height: VSpacing.space4),
              VButton(
                label: 'Đóng',
                variant: VButtonVariant.secondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    ),
  );
}
