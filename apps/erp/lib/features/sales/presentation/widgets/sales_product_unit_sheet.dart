import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

import '../models/shared/sales_sellable_product_vm.dart';
import 'package:erp/core/formatting/money_formatter.dart';
/// O-01 — Select Sheet chọn đơn vị bán khi sản phẩm có nhiều unit.
///
/// Mặc định chọn đơn vị cơ sở; xác nhận mới trả unit về caller.
abstract final class SalesProductUnitSheet {
  static Future<SalesProductUnitVm?> show(
    BuildContext context, {
    required SalesSellableProductVm product,
    String? initialUnitId,
  }) {
    // TODO(design-system): showVBottomSheet chưa hỗ trợ heightFraction / snap
    // (vd. initialChildSize: 2/3, snap sizes). Khi DS thêm API, thay SizedBox
    // height thủ công bằng param chính thức.
    return showVBottomSheet<SalesProductUnitVm>(
      context: context,
      child: _SalesProductUnitSheetBody(
        product: product,
        initialUnitId: initialUnitId,
      ),
    );
  }
}

class _SalesProductUnitSheetBody extends StatefulWidget {
  const _SalesProductUnitSheetBody({
    required this.product,
    this.initialUnitId,
  });

  final SalesSellableProductVm product;
  final String? initialUnitId;

  @override
  State<_SalesProductUnitSheetBody> createState() => _SalesProductUnitSheetBodyState();
}

class _SalesProductUnitSheetBodyState extends State<_SalesProductUnitSheetBody> {
  late String _selectedUnitId;

  List<SalesProductUnitVm> get _units => widget.product.selectableUnits;

  @override
  void initState() {
    super.initState();
    final preferredId = widget.initialUnitId?.trim();
    SalesProductUnitVm? preferred;
    if (preferredId != null && preferredId.isNotEmpty) {
      for (final unit in _units) {
        if (unit.productUnitId == preferredId) {
          preferred = unit;
          break;
        }
      }
    }
    final initial = preferred ?? widget.product.defaultUnit ?? _units.first;
    _selectedUnitId = initial.productUnitId;
  }

  SalesProductUnitVm get _selectedUnit =>
      _units.firstWhere((unit) => unit.productUnitId == _selectedUnitId);

  void _select(String unitId) {
    if (unitId == _selectedUnitId) return;
    setState(() => _selectedUnitId = unitId);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final sheetHeight = MediaQuery.sizeOf(context).height / 3;

    return SizedBox(
      height: sheetHeight,
      child: VPagePadding(
        child: Column(
          key: const Key('wgt_sg03_unit_sheet'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VText(
              'Chọn đơn vị bán',
              variant: VTextVariant.headingH4,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const VGap.md(),
            Expanded(
              child: RadioGroup<String>(
                groupValue: _selectedUnitId,
                onChanged: (value) {
                  if (value != null) _select(value);
                },
                child: ListView.separated(
                  itemCount: _units.length,
                  separatorBuilder: (_, _) => const VGap.sm(),
                  itemBuilder: (context, index) {
                    final unit = _units[index];
                    final selected = unit.productUnitId == _selectedUnitId;
                    return VCard(
                      key: Key('action_sg03_unit_${unit.productUnitId}'),
                      tone: selected ? VComponentTone.primary : null,
                      onTap: () => _select(unit.productUnitId),
                      child: Row(
                        children: [
                          VIconBox(
                            icon: VIcons.inventory,
                            size: 36,
                            iconSize: 20,
                            backgroundColor: selected ? colors.successBgPressed : colors.surfaceAlt,
                            iconColor: selected ? colors.textBrand : colors.textSecondary,
                            borderRadius: VRadius.card,
                          ),
                          const VGap.horizontalSm(),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                VText(
                                  unit.unitName,
                                  variant: VTextVariant.bodyDefault,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                const VGap.xs(),
                                VText(
                                  _subtitle(unit),
                                  variant: VTextVariant.bodySmall,
                                  color: colors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                          const VGap.horizontalSm(),
                          IgnorePointer(
                            child: VRadio<String>(
                              value: unit.productUnitId,
                              onChanged: null,
                              semanticLabel: unit.unitName,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const VGap.md(),
            Row(
              children: [
                Expanded(
                  child: VButton(
                    key: const Key('btn_sg03_unit_cancel'),
                    label: 'Hủy',
                    variant: VButtonVariant.secondary,
                    fullWidth: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const VGap.horizontalSm(),
                Expanded(
                  child: VButton(
                    key: const Key('btn_sg03_unit_confirm'),
                    label: 'Xác nhận',
                    variant: VButtonVariant.primary,
                    fullWidth: true,
                    onPressed: () => Navigator.of(context).pop(_selectedUnit),
                  ),
                ),
              ],
            ),
            const VGap.sm(),
          ],
        ),
      ),
    );
  }

  static String _subtitle(SalesProductUnitVm unit) {
    final price = MoneyFormatter.format(amountMinor: unit.unitPrice.amountMinor, currencyCode: unit.unitPrice.currencyCode);
    final stock = unit.stockQuantity;
    if (stock == null) return price;
    return '$price · Tồn $stock';
  }
}
