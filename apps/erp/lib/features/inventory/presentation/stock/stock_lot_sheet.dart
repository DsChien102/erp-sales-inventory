import 'package:erp/features/inventory/data/stock/stock_models.dart';
import 'package:erp/features/inventory/logic/inventory_format.dart';
import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

class StockLotSheet extends StatelessWidget {
  final StockLot lot;
  final String productName;
  final String uom;
  final VoidCallback? onAdjustExpired;

  const StockLotSheet({
    super.key,
    required this.lot,
    required this.productName,
    required this.uom,
    this.onAdjustExpired,
  });

  static Future<void> show({
    required BuildContext context,
    required StockLot lot,
    required String productName,
    required String uom,
    VoidCallback? onAdjustExpired,
  }) {
    return showVAdaptiveSheet<void>(
      context: context,
      title: 'Lô ${lot.code}',
      child: StockLotSheet(
        lot: lot,
        productName: productName,
        uom: uom,
        onAdjustExpired: onAdjustExpired,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expiryText = lot.expiry?.format() ?? 'Không có HSD';
    final eligibleQty = lot.isExpired ? 0 : lot.physical;

    return Padding(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$productName · HSD $expiryText',
            style: TextStyle(
              fontSize: 13,
              height: 20 / 13,
              color: context.vColors.textSecondary,
            ),
          ),
          const SizedBox(height: VSpacing.space3),
          VKeyValueGroup(
            rows: [
              VKeyValueRow(
                label: 'Tồn vật lý',
                value: formatStockQuantity(lot.physical, uom),
                mono: true,
              ),
              VKeyValueRow(
                label: 'Đủ điều kiện bán',
                value: formatStockQuantity(eligibleQty, uom),
                mono: true,
              ),
            ],
          ),
          if (lot.isExpired) ...[
            const SizedBox(height: VSpacing.space3),
            const VBanner(
              tone: VComponentTone.danger,
              title: 'Hết hạn',
              description: 'Lượng của lô này không đủ điều kiện bán.',
            ),
            if (onAdjustExpired != null) ...[
              const SizedBox(height: VSpacing.space3),
              VButton(
                label: 'Điều chỉnh lô hết hạn',
                variant: VButtonVariant.secondary,
                onPressed: () {
                  final nav = Navigator.of(context);
                  if (nav.canPop()) nav.pop();
                  onAdjustExpired!();
                },
              ),
            ],
          ] else if (lot.isNearExpiry) ...[
            const SizedBox(height: VSpacing.space3),
            VBanner(
              tone: VComponentTone.warning,
              title: 'Cận hạn',
              description:
                  '${lot.daysToExpiry != null ? 'Còn ${lot.daysToExpiry} ngày · ' : ''}vẫn đủ điều kiện bán theo chính sách hiện tại.',
            ),
          ],
        ],
      ),
    );
  }
}

