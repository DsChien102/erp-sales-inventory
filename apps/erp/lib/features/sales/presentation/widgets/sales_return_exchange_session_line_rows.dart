import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_sales_application/application.dart';

import '../bloc/return_exchange_order/sales_return_exchange_session_state.dart';
import 'package:erp/core/formatting/money_formatter.dart';
import 'sales_order_line_quantity.dart';

/// One returnable line with quantity controls.
class SalesReturnExchangeReturnLineRow extends StatelessWidget {
  const SalesReturnExchangeReturnLineRow({
    super.key,
    required this.line,
    required this.edit,
    required this.reasons,
    required this.conditions,
    required this.enabled,
    required this.onQuantityChanged,
    required this.onReasonChanged,
    required this.onConditionChanged,
  });

  final ReturnableOrderLineDto line;
  final SalesReturnLineEdit? edit;
  final List<ReturnExchangePolicyOptionDto> reasons;
  final List<ReturnExchangePolicyOptionDto> conditions;
  final bool enabled;
  final void Function(String salesOrderLineId, int quantityMicros) onQuantityChanged;
  final void Function(String salesOrderLineId, String reasonCode) onReasonChanged;
  final void Function(String salesOrderLineId, String conditionCode) onConditionChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final id = line.unitId;
    final units = (edit?.quantityMicros ?? 0) ~/ QuantityDto.scale;
    final priceLabel = MoneyFormatter.format(amountMinor: line.originalUnitPrice.amountMinor, currencyCode: line.originalUnitPrice.currencyCode);
    final maxUnits = line.returnableQuantity.quantityMicros ~/ QuantityDto.scale;

    return Padding(
      padding: const EdgeInsets.all(VSpacing.space2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(VRadius.r8),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: colors.textMuted,
                ),
              ),
              const VGap.horizontalSm(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VText(
                      line.product.displayName,
                      variant: VTextVariant.bodyDefault,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const VGap.xs(),
                    VText(
                      '$priceLabel/${line.unit.unitName}',
                      variant: VTextVariant.bodySmall,
                      color: colors.textSecondary,
                    ),
                  ],
                ),
              ),
              const VGap.horizontalSm(),
              SalesOrderLineQuantityControls(
                key: Key('qty_return_$id'),
                quantity: units,
                enabled: enabled,
                onDecrement: () {
                  if (units > 0) {
                    onQuantityChanged(id, (units - 1) * QuantityDto.scale);
                  }
                },
                onIncrement: () {
                  if (units < maxUnits) {
                    onQuantityChanged(id, (units + 1) * QuantityDto.scale);
                  }
                },
              ),
            ],
          ),
          // Temporarily skip return reason/condition policy selection in the
          // SG-11 entry flow until the policy setup screen is reintroduced.
        ],
      ),
    );
  }
}

/// One exchange edit row with quantity controls.
class SalesReturnExchangeExchangeLineRow extends StatelessWidget {
  const SalesReturnExchangeExchangeLineRow({
    super.key,
    required this.edit,
    required this.enabled,
    required this.onQuantityChanged,
  });

  final SalesExchangeLineEdit edit;
  final bool enabled;
  final void Function(String productUnitId, int quantityMicros) onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final units = edit.quantityMicros ~/ QuantityDto.scale;
    final priceLabel = MoneyFormatter.format(amountMinor: edit.unitPrice.amountMinor, currencyCode: edit.unitPrice.currencyCode);

    return Padding(
      padding: const EdgeInsets.all(VSpacing.space2),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.surfaceAlt,
              borderRadius: BorderRadius.circular(VRadius.r8),
            ),
            child: Icon(
              Icons.local_pharmacy_outlined,
              color: colors.textMuted,
            ),
          ),
          const VGap.horizontalSm(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(
                  edit.productName,
                  variant: VTextVariant.bodyDefault,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const VGap.xs(),
                VText(
                  '$priceLabel/${edit.unitLabel}',
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
          const VGap.horizontalSm(),
          SalesOrderLineQuantityControls(
            key: Key('qty_exchange_${edit.productUnitId}'),
            quantity: units,
            enabled: enabled,
            onDecrement: () {
              onQuantityChanged(
                edit.productUnitId,
                (units - 1) * QuantityDto.scale,
              );
            },
            onIncrement: () {
              onQuantityChanged(
                edit.productUnitId,
                (units + 1) * QuantityDto.scale,
              );
            },
          ),
        ],
      ),
    );
  }
}
