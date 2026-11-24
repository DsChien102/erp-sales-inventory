import 'package:erp/core/formatting/money_formatter.dart';
import 'package:erp/features/inventory/data/reports/reports_models.dart';
import 'package:erp/features/inventory/logic/costing/costing_rules.dart';
import 'package:erp/features/inventory/logic/reports/reports_rules.dart';
import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

/// Chiết khấu NCC hiện `−{x}` khi > 0, không có ⇒ `—`.
String rebateText(int rebateVnd) =>
    rebateVnd > 0 ? signedMoney(-rebateVnd) : '—';

/// Chi tiết lãi gộp của một sản phẩm: 9 dòng số.
Future<void> showGrossProfitProductSheet(
  BuildContext context,
  GrossProfitRow row,
) {
  return showVAdaptiveSheet<void>(
    context: context,
    title: row.name,
    child: GrossProfitProductSheetBody(row: row),
  );
}

class GrossProfitProductSheetBody extends StatelessWidget {
  const GrossProfitProductSheetBody({super.key, required this.row});

  final GrossProfitRow row;

  @override
  Widget build(BuildContext context) {
    Widget kv(String label, String value, {bool emphasized = false}) =>
        VKeyValueRow(
          label: label,
          value: value,
          mono: true,
          emphasized: emphasized,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        kv('Doanh thu', MoneyFormatter.formatMinor(row.revenueVnd)),
        kv('Giảm trừ (trả / huỷ)', MoneyFormatter.formatMinor(row.deductionVnd)),
        kv('Doanh thu thuần', MoneyFormatter.formatMinor(row.netRevenueVnd)),
        kv('Giá vốn lúc bán', MoneyFormatter.formatMinor(row.cogsAtSaleVnd)),
        kv('Điều chỉnh', signedMoney(row.cogsAdjustVnd)),
        kv('Chiết khấu NCC', rebateText(row.rebateVnd)),
        kv('Giá vốn sau điều chỉnh', MoneyFormatter.formatMinor(row.cogsAfterVnd)),
        kv('Lãi gộp', signedMoney(row.grossProfitVnd), emphasized: true),
        kv('Tỷ lệ', marginText(row.marginPct)),
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
}
