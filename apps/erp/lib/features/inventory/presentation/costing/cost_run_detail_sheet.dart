import 'package:erp/features/inventory/data/costing/costing_models.dart';
import 'package:erp/features/inventory/logic/costing/costing_rules.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_layout.dart';
import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';

/// Sheet "Chi tiết tính" (chỉ đọc, SCR-074).
Future<void> showCostRunDetailSheet(
  BuildContext context, {
  required CostRunView run,
}) {
  return showVAdaptiveSheet<void>(
    context: context,
    title: 'Chi tiết tính',
    child: _CostRunDetailSheetBody(run: run),
  );
}

class _DetailRow {
  const _DetailRow.line(this.line) : total = null;
  const _DetailRow.total(this.total) : line = null;

  final CostRunLineView? line;
  final _DetailTotal? total;
}

class _DetailTotal {
  const _DetailTotal({
    required this.openingValue,
    required this.inboundValue,
    required this.rebateValue,
    required this.saleValue,
    required this.lossValue,
    required this.closingValue,
    required this.lineAdjust,
  });

  final int openingValue;
  final int inboundValue;
  final int rebateValue;
  final int saleValue;
  final int lossValue;
  final int closingValue;
  final int lineAdjust;
}

class _CostRunDetailSheetBody extends StatelessWidget {
  const _CostRunDetailSheetBody({required this.run});

  final CostRunView run;

  String _fmtQty(num q) {
    if (q == q.truncateToDouble()) return q.toInt().toString();
    return q.toStringAsFixed(2);
  }

  _DetailTotal _computeTotal() {
    var opening = 0;
    var inbound = 0;
    var rebate = 0;
    var sale = 0;
    var loss = 0;
    var closing = 0;
    var adjust = 0;
    for (final l in run.lines) {
      opening += l.openingValue;
      inbound += l.inboundValue;
      rebate += l.rebateValue;
      sale += l.saleValueRecorded + l.cogsTrueUp;
      loss += l.lossValueRecorded + l.lossTrueUp;
      closing += l.closingValueAfter;
      adjust += l.lineAdjust;
    }
    return _DetailTotal(
      openingValue: opening,
      inboundValue: inbound,
      rebateValue: rebate,
      saleValue: sale,
      lossValue: loss,
      closingValue: closing,
      lineAdjust: adjust,
    );
  }

  Widget _qtyMoneyCell(
    BuildContext context, {
    required num qty,
    required int money,
  }) {
    final colors = context.vColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _fmtQty(qty),
          style: VTypography.monoNumeric.copyWith(color: colors.textPrimary),
        ),
        Text(
          moneyWithSpace(money),
          style: VTypography.monoNumeric.copyWith(
            fontSize: 12,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _moneyCell(BuildContext context, int money, {bool bold = false}) {
    return Text(
      moneyWithSpace(money),
      style: VTypography.monoNumeric.copyWith(
        fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
        color: context.vColors.textPrimary,
      ),
    );
  }

  List<K7Column<_DetailRow>> _columns(BuildContext context) {
    final colors = context.vColors;
    return [
      K7Column<_DetailRow>(
        label: 'Sản phẩm',
        cell: (r) => Text(
          r.line?.name ?? 'Tổng',
          style: VTypography.bodyDefault.copyWith(
            fontWeight: r.line == null ? FontWeight.w700 : FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ),
      K7Column<_DetailRow>(
        label: 'Tồn đầu',
        numeric: true,
        cell: (r) => r.line != null
            ? _qtyMoneyCell(
                context,
                qty: r.line!.openingQty,
                money: r.line!.openingValue,
              )
            : _moneyCell(context, r.total!.openingValue, bold: true),
      ),
      K7Column<_DetailRow>(
        label: 'Nhập',
        numeric: true,
        cell: (r) => r.line != null
            ? _qtyMoneyCell(
                context,
                qty: r.line!.inboundQty,
                money: r.line!.inboundValue,
              )
            : _moneyCell(context, r.total!.inboundValue, bold: true),
      ),
      K7Column<_DetailRow>(
        label: 'Chiết khấu NCC',
        numeric: true,
        cell: (r) => _moneyCell(
          context,
          r.line?.rebateValue ?? r.total!.rebateValue,
          bold: r.line == null,
        ),
      ),
      K7Column<_DetailRow>(
        label: 'Xuất bán',
        numeric: true,
        cell: (r) => r.line != null
            ? _qtyMoneyCell(
                context,
                qty: r.line!.saleQty,
                money: r.line!.saleValueRecorded + r.line!.cogsTrueUp,
              )
            : _moneyCell(context, r.total!.saleValue, bold: true),
      ),
      K7Column<_DetailRow>(
        label: 'Hao hụt',
        numeric: true,
        cell: (r) => r.line != null
            ? _qtyMoneyCell(
                context,
                qty: r.line!.lossQty,
                money: r.line!.lossValueRecorded + r.line!.lossTrueUp,
              )
            : _moneyCell(context, r.total!.lossValue, bold: true),
      ),
      K7Column<_DetailRow>(
        label: 'Tồn cuối',
        numeric: true,
        cell: (r) => r.line != null
            ? _qtyMoneyCell(
                context,
                qty: r.line!.closingQty,
                money: r.line!.closingValueAfter,
              )
            : _moneyCell(context, r.total!.closingValue, bold: true),
      ),
      K7Column<_DetailRow>(
        label: 'Bình quân liên hoàn',
        numeric: true,
        cell: (r) => r.line != null
            ? _moneyCell(context, r.line!.movingAvgEnd.round())
            : const Text('—'),
      ),
      K7Column<_DetailRow>(
        label: 'Bình quân cuối kỳ',
        numeric: true,
        cell: (r) => r.line?.periodicAvg != null
            ? _moneyCell(context, r.line!.periodicAvg!.round())
            : const Text('—'),
      ),
      K7Column<_DetailRow>(
        label: 'Điều chỉnh',
        numeric: true,
        cell: (r) => Text(
          signedMoney(r.line?.lineAdjust ?? r.total!.lineAdjust),
          style: VTypography.monoNumeric.copyWith(
            fontWeight: r.line == null ? FontWeight.w600 : FontWeight.w400,
            color: colors.textPrimary,
          ),
        ),
      ),
    ];
  }

  Widget _mobileLineGroup(CostRunLineView l) {
    final saleTotal = l.saleValueRecorded + l.cogsTrueUp;
    final lossTotal = l.lossValueRecorded + l.lossTrueUp;
    return VKeyValueGroup(
      title: l.name,
      rows: [
        VKeyValueRow(
          label: 'Tồn đầu',
          value: '${_fmtQty(l.openingQty)} ${l.uom} · ${moneyWithSpace(l.openingValue)}',
          mono: true,
        ),
        VKeyValueRow(
          label: 'Nhập',
          value: '${_fmtQty(l.inboundQty)} ${l.uom} · ${moneyWithSpace(l.inboundValue)}',
          mono: true,
        ),
        VKeyValueRow(
          label: 'Chiết khấu NCC',
          value: moneyWithSpace(l.rebateValue),
          mono: true,
        ),
        VKeyValueRow(
          label: 'Xuất bán',
          value: '${_fmtQty(l.saleQty)} ${l.uom} · ${moneyWithSpace(saleTotal)}',
          mono: true,
        ),
        VKeyValueRow(
          label: 'Hao hụt',
          value: '${_fmtQty(l.lossQty)} ${l.uom} · ${moneyWithSpace(lossTotal)}',
          mono: true,
        ),
        VKeyValueRow(
          label: 'Tồn cuối',
          value: '${_fmtQty(l.closingQty)} ${l.uom} · ${moneyWithSpace(l.closingValueAfter)}',
          mono: true,
        ),
        VKeyValueRow(
          label: 'Bình quân liên hoàn',
          value: '${moneyWithSpace(l.movingAvgEnd.round())}/${l.uom}',
          mono: true,
        ),
        VKeyValueRow(
          label: 'Bình quân cuối kỳ',
          value: l.periodicAvg != null
              ? '${moneyWithSpace(l.periodicAvg!.round())}/${l.uom}'
              : '—',
          mono: true,
        ),
        VKeyValueRow(
          label: 'Điều chỉnh',
          value: signedMoney(l.lineAdjust),
          mono: true,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = inventoryIsWide(context);
    final total = _computeTotal();
    final rows = [
      for (final l in run.lines) _DetailRow.line(l),
      if (run.lines.isNotEmpty) _DetailRow.total(total),
    ];
    final balanceDiffSum = run.lines.fold<int>(0, (s, l) => s + l.balanceDiff);
    final isBalanced = run.totals.balanceOk && balanceDiffSum == 0;

    return Padding(
      padding: const EdgeInsets.all(VSpacing.space4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: isWide
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: K7Table<_DetailRow>(
                        columns: _columns(context),
                        rows: rows,
                        mobileRow: (r) => r.line != null
                            ? _mobileLineGroup(r.line!)
                            : const SizedBox.shrink(),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < run.lines.length; i++) ...[
                          _mobileLineGroup(run.lines[i]),
                          if (i < run.lines.length - 1)
                            const SizedBox(height: VSpacing.space3),
                        ],
                      ],
                    ),
            ),
          ),
          const SizedBox(height: VSpacing.space3),
          Align(
            alignment: Alignment.centerLeft,
            child: VBadge(
              label: isBalanced
                  ? 'Kiểm cân bằng: Khớp'
                  : 'Kiểm cân bằng: Lệch ${signedMoney(balanceDiffSum)}',
              tone:
                  isBalanced ? VComponentTone.success : VComponentTone.warning,
            ),
          ),
          const SizedBox(height: VSpacing.space2),
          VText(
            'Tồn đầu + Nhập − Chiết khấu NCC = Giá vốn xuất + Hao hụt + Tồn cuối',
            variant: VTextVariant.bodySmall,
            color: context.vColors.textSecondary,
          ),
          const SizedBox(height: VSpacing.space4),
          VButton(
            label: 'Đóng',
            variant: VButtonVariant.secondary,
            fullWidth: !isWide,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
