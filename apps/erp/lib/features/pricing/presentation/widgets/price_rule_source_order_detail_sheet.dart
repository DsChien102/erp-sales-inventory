import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// D-06 SG-06 — Sheet xem thông tin chứng từ nguồn / đơn hàng nguồn.
class PriceRuleSourceOrderDetailSheet extends StatelessWidget {
  const PriceRuleSourceOrderDetailSheet({
    super.key,
    required this.orderId,
    required this.customerName,
    required this.orderDate,
    required this.productName,
    required this.unitName,
    required this.priceLabel,
    required this.staffName,
    this.onViewSourceOrder,
  });

  final String orderId;
  final String customerName;
  final String orderDate;
  final String productName;
  final String unitName;
  final String priceLabel;
  final String staffName;
  final VoidCallback? onViewSourceOrder;

  static Future<void> show({
    required BuildContext context,
    required String orderId,
    required String customerName,
    required String orderDate,
    required String productName,
    required String unitName,
    required String priceLabel,
    required String staffName,
    VoidCallback? onViewSourceOrder,
  }) {
    return showVBottomSheet(
      context: context,
      semanticLabel: 'Chứng từ nguồn đơn hàng',
      child: PriceRuleSourceOrderDetailSheet(
        orderId: orderId,
        customerName: customerName,
        orderDate: orderDate,
        productName: productName,
        unitName: unitName,
        priceLabel: priceLabel,
        staffName: staffName,
        onViewSourceOrder: onViewSourceOrder,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            VSpacing.space4,
            VSpacing.space2,
            VSpacing.space4,
            VSpacing.space4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  VText(
                    'Chứng từ nguồn',
                    variant: VTextVariant.headingH4,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    color: colors.textPrimary,
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(VRadius.r8),
                    child: Padding(
                      padding: const EdgeInsets.all(VSpacing.space1),
                      child: VIcon(
                        icon: VIcons.close,
                        size: 20,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const VGap.md(),
              Center(
                child: VIconBox(
                  icon: VIcons.receipt,
                  size: 64,
                  iconSize: 32,
                  tone: VComponentTone.success,
                  isCircular: true,
                ),
              ),
              const VGap.sm(),
              VText(
                'Đơn hàng $orderId',
                variant: VTextVariant.bodyDefault,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const VGap.md(),
              VCard(
                padding: const EdgeInsets.all(VSpacing.space4),
                child: Column(
                  children: [
                    _RowItem(label: 'Khách hàng', value: customerName),
                    const VGap.sm(),
                    _RowItem(label: 'Ngày bán', value: orderDate, numeric: true),
                    const VGap.sm(),
                    _RowItem(label: 'Sản phẩm', value: productName),
                    const VGap.sm(),
                    _RowItem(label: 'Đơn vị', value: unitName),
                    const VGap.sm(),
                    _RowItem(
                      label: 'Giá bán',
                      value: priceLabel,
                      numeric: true,
                      valueWeight: FontWeight.w700,
                    ),
                    const VGap.sm(),
                    _RowItem(label: 'Nhân viên', value: staffName),
                  ],
                ),
              ),
              const VGap.lg(),
              VButton(
                label: 'Xem đơn hàng nguồn',
                variant: VButtonVariant.primary,
                fullWidth: true,
                onPressed: () {
                  Navigator.of(context).pop();
                  onViewSourceOrder?.call();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  const _RowItem({
    required this.label,
    required this.value,
    this.numeric = false,
    this.valueWeight,
  });

  final String label;
  final String value;
  final bool numeric;
  final FontWeight? valueWeight;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        VText(
          label,
          variant: VTextVariant.bodyDefault,
          color: colors.textSecondary,
        ),
        const VGap.horizontalSm(),
        Flexible(
          child: VText(
            value,
            variant: numeric ? VTextVariant.monoNumeric : VTextVariant.bodyDefault,
            color: colors.textPrimary,
            textAlign: TextAlign.end,
            style: valueWeight != null ? TextStyle(fontWeight: valueWeight) : null,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
