import 'package:erp/core/formatting/money_formatter.dart';
import 'package:erp/features/inventory/data/reports/reports_models.dart';
import 'package:erp/features/inventory/logic/inventory_format.dart';
import 'package:erp/features/inventory/logic/reports/reports_rules.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_layout.dart';
import 'package:erp/features/inventory/presentation/reports/reports_ui.dart';
import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Sản phẩm đã nhập từ một nhà cung cấp trong kỳ.
Future<void> showSupplierPurchaseSheet(
  BuildContext context,
  SupplierPurchaseRow supplier,
) {
  return showVAdaptiveSheet<void>(
    context: context,
    title: supplier.name,
    child: SupplierPurchaseSheetBody(supplier: supplier),
  );
}

class SupplierPurchaseSheetBody extends StatelessWidget {
  const SupplierPurchaseSheetBody({super.key, required this.supplier});

  final SupplierPurchaseRow supplier;

  @override
  Widget build(BuildContext context) {
    final isWide = inventoryIsWide(context);
    final products = supplier.products;

    Widget list;
    if (products.isEmpty) {
      list = const ReportNote('Không có sản phẩm nhập trong kỳ.');
    } else if (isWide) {
      list = K7Table<SupplierPurchaseProduct>(
        columns: _columns(),
        rows: products,
        mobileRow: _mobileRow,
      );
    } else {
      list = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < products.length; i++) ...[
            _mobileRow(products[i]),
            if (i < products.length - 1) const SizedBox(height: VSpacing.space2),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (supplier.rebateVnd > 0) ...[
          VKeyValueRow(
            label: 'Chiết khấu đạt mốc',
            value: MoneyFormatter.formatMinor(supplier.rebateVnd),
            mono: true,
          ),
          const SizedBox(height: VSpacing.space2),
        ],
        Flexible(child: SingleChildScrollView(child: list)),
        const SizedBox(height: VSpacing.space4),
        VButton(
          label: 'Đóng',
          variant: VButtonVariant.secondary,
          fullWidth: true,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _mobileRow(SupplierPurchaseProduct p) {
    return Builder(
      builder: (context) {
        final colors = context.vColors;
        return VListRow(
          title: p.name,
          subtitle: 'Mua ${formatQuantity(p.paidQty.toDouble())} · '
              'Tặng ${formatQuantity(p.freeQty.toDouble())} ${p.uom}',
          type: VListRowType.plain,
          trailing: Text(
            MoneyFormatter.formatMinor(p.landedVnd),
            style: VTypography.monoNumeric.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          contentBelow: p.avgLandedUnitCost == null
              ? null
              : Text(
                  'Đơn giá gốc ${unitCostText(p.avgLandedUnitCost!)}/${p.uom}',
                  style: VTypography.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
        );
      },
    );
  }

  List<K7Column<SupplierPurchaseProduct>> _columns() {
    Widget num(String text) =>
        Builder(builder: (ctx) => reportNumberCell(ctx, text));
    return [
      K7Column<SupplierPurchaseProduct>(
        label: 'Sản phẩm',
        cell: (p) => Builder(
          builder: (ctx) => reportProductCell(
            ctx,
            name: p.name,
            sub: [p.code, p.uom].where((e) => e.isNotEmpty).join(' · '),
          ),
        ),
      ),
      K7Column<SupplierPurchaseProduct>(
        label: 'SL mua',
        numeric: true,
        cell: (p) => num(formatQuantity(p.paidQty.toDouble())),
      ),
      K7Column<SupplierPurchaseProduct>(
        label: 'SL tặng',
        numeric: true,
        cell: (p) => num(formatQuantity(p.freeQty.toDouble())),
      ),
      K7Column<SupplierPurchaseProduct>(
        label: 'Tiền mua',
        numeric: true,
        cell: (p) => num(MoneyFormatter.formatMinor(p.purchaseVnd)),
      ),
      K7Column<SupplierPurchaseProduct>(
        label: 'Giá gốc',
        numeric: true,
        cell: (p) => num(MoneyFormatter.formatMinor(p.landedVnd)),
      ),
      K7Column<SupplierPurchaseProduct>(
        label: 'Đơn giá gốc',
        numeric: true,
        cell: (p) => num(
          p.avgLandedUnitCost == null
              ? '—'
              : '${unitCostText(p.avgLandedUnitCost!)}/${p.uom}',
        ),
      ),
    ];
  }
}
