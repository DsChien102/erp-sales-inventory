import 'package:erp/core/formatting/money_formatter.dart';
import 'package:erp/features/inventory/data/supplier_rebate/supplier_rebate_models.dart';
import 'package:erp/features/inventory/logic/supplier_program/supplier_program_rules.dart';
import 'package:erp/features/inventory/presentation/patterns/inventory_layout.dart';
import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

String _moneyOrDash(int? vnd) =>
    vnd == null ? '—' : '${MoneyFormatter.formatMinorPlain(vnd)} đ';

String _qtyPair(RebateAllocation a) {
  final suffix = a.uom.trim().isNotEmpty ? ' ${a.uom.trim()}' : '';
  return '${formatProgramQuantity(a.onHandQty)} / ${formatProgramQuantity(a.paidQty)}$suffix';
}

String _avgChange(RebateAllocation a) {
  if (a.avgCostBefore == null || a.avgCostAfter == null) {
    return '—';
  }
  final before = MoneyFormatter.formatMinorPlain(a.avgCostBefore!.round());
  final after = MoneyFormatter.formatMinorPlain(a.avgCostAfter!.round());
  final perUom = a.uom.trim().isNotEmpty ? '/${a.uom.trim()}' : '';
  return '$before → $after đ$perUom';
}

/// Khối hiển thị bảng / thẻ phân bổ chiết khấu xem trước theo sản phẩm (P4).
class RebateAllocationView extends StatelessWidget {
  const RebateAllocationView({
    super.key,
    required this.preview,
    required this.previewLoading,
    this.previewErrorCode,
  });

  final RebatePreview? preview;
  final bool previewLoading;
  final String? previewErrorCode;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final data = preview;

    return VSection(
      title: 'Phân bổ (xem trước)',
      child: previewLoading || data == null
          ? const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                VSkeleton(
                  width: double.infinity,
                  height: 96,
                  borderRadius: VRadius.r12,
                ),
                SizedBox(height: VSpacing.space2),
                VSkeleton(
                  width: double.infinity,
                  height: 44,
                  borderRadius: VRadius.r12,
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (previewErrorCode != null) ...[
                  const VBanner(
                    tone: VComponentTone.warning,
                    title: 'Không cập nhật được phân bổ xem trước. Thử lại.',
                  ),
                  const SizedBox(height: VSpacing.space2),
                ],
                K7Table<RebateAllocation>(
                  columns: [
                    K7Column<RebateAllocation>(
                      label: 'Sản phẩm',
                      cell: (a) => VText(
                        a.name,
                        variant: VTextVariant.bodyDefault,
                        color: colors.textPrimary,
                      ),
                    ),
                    K7Column<RebateAllocation>(
                      label: 'Tồn / mua',
                      numeric: true,
                      cell: (a) => VText(
                        _qtyPair(a),
                        variant: VTextVariant.bodySmallMono,
                        color: colors.textPrimary,
                      ),
                    ),
                    K7Column<RebateAllocation>(
                      label: 'Chiết khấu',
                      numeric: true,
                      cell: (a) => VText(
                        _moneyOrDash(a.rebatePartVnd),
                        variant: VTextVariant.bodySmallMono,
                        color: colors.textPrimary,
                      ),
                    ),
                    K7Column<RebateAllocation>(
                      label: 'Giảm giá trị tồn',
                      numeric: true,
                      cell: (a) => VText(
                        _moneyOrDash(a.inventoryPartVnd),
                        variant: VTextVariant.bodySmallMono,
                        color: colors.textPrimary,
                      ),
                    ),
                    K7Column<RebateAllocation>(
                      label: 'Giảm giá vốn',
                      numeric: true,
                      cell: (a) => VText(
                        _moneyOrDash(a.cogsPartVnd),
                        variant: VTextVariant.bodySmallMono,
                        color: colors.textPrimary,
                      ),
                    ),
                    K7Column<RebateAllocation>(
                      label: 'Bình quân',
                      numeric: true,
                      cell: (a) => VText(
                        _avgChange(a),
                        variant: VTextVariant.bodySmallMono,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                  rows: data.allocations,
                  mobileRow: (a) => _MobileAllocationCard(allocation: a),
                ),
                const Divider(height: VSpacing.space4),
                VText(
                  'Tổng  tồn ${MoneyFormatter.formatMinorPlain(data.inventoryPartTotal)} · '
                  'giá vốn ${MoneyFormatter.formatMinorPlain(data.cogsPartTotal)}',
                  variant: VTextVariant.bodySmallMono,
                  color: colors.textSecondary,
                  textAlign: TextAlign.right,
                ),
              ],
            ),
    );
  }
}

class _MobileAllocationCard extends StatelessWidget {
  const _MobileAllocationCard({required this.allocation});

  final RebateAllocation allocation;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final suffix =
        allocation.uom.trim().isNotEmpty ? ' ${allocation.uom.trim()}' : '';

    return VCard(
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: VText(
                    allocation.name,
                    variant: VTextVariant.bodyDefault,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(width: VSpacing.space2),
                VText(
                  _moneyOrDash(allocation.rebatePartVnd),
                  variant: VTextVariant.bodyDefaultMono,
                  color: colors.textPrimary,
                ),
              ],
            ),
            const SizedBox(height: VSpacing.space1),
            VText(
              'Tồn ${formatProgramQuantity(allocation.onHandQty)} / '
              'mua ${formatProgramQuantity(allocation.paidQty)}$suffix',
              variant: VTextVariant.bodySmall,
              color: colors.textSecondary,
            ),
            const SizedBox(height: VSpacing.space2),
            VKeyValueGroup(
              rows: [
                VKeyValueRow(
                  label: 'Giảm giá trị tồn',
                  value: _moneyOrDash(allocation.inventoryPartVnd),
                  mono: true,
                ),
                VKeyValueRow(
                  label: 'Giảm giá vốn hàng đã bán',
                  value: _moneyOrDash(allocation.cogsPartVnd),
                  mono: true,
                ),
                VKeyValueRow(
                  label: 'Bình quân',
                  value: _avgChange(allocation),
                  mono: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
