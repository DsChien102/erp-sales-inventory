import 'package:erp/core/formatting/money_formatter.dart';
import 'package:erp/features/inventory/data/supplier_rebate/supplier_rebate_models.dart';
import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

String _moneyOrDash(int? vnd) =>
    vnd == null ? '—' : '${MoneyFormatter.formatMinorPlain(vnd)} đ';

String _formatDate(DateTime date) {
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  final y = date.year.toString();
  return '$d/$m/$y';
}

String _formatDateTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}

/// Khối hiển thị thông tin chiết khấu đã ghi nhận trên P3 (trạng thái RECORDED).
class RecordedRebateSection extends StatelessWidget {
  const RecordedRebateSection({super.key, required this.rebate});

  final RecordedRebate rebate;

  @override
  Widget build(BuildContext context) {
    final overrideReason = rebate.overrideReason?.trim();
    return VSection(
      title: 'Chiết khấu đã ghi nhận',
      child: VKeyValueGroup(
        rows: [
          VKeyValueRow(
            label: 'Chứng từ',
            value: '${rebate.documentNo} · ${_formatDate(rebate.documentDate)}',
            mono: true,
          ),
          VKeyValueRow(
            label: 'Số tiền',
            value: _moneyOrDash(rebate.rebateAmountVnd),
            mono: true,
          ),
          VKeyValueRow(
            label: 'Giảm giá trị tồn',
            value: _moneyOrDash(rebate.inventoryPartVnd),
            mono: true,
          ),
          VKeyValueRow(
            label: 'Giảm giá vốn hàng đã bán',
            value: _moneyOrDash(rebate.cogsPartVnd),
            mono: true,
          ),
          if (overrideReason != null && overrideReason.isNotEmpty)
            VKeyValueRow(
              label: 'Lý do khác đề xuất',
              value: overrideReason,
            ),
          VKeyValueRow(
            label: 'Ghi nhận lúc',
            value: _formatDateTime(rebate.recordedAt),
            mono: true,
          ),
        ],
      ),
    );
  }
}

