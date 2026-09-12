import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../models/sales_order_draft/sales_compose_line_vm.dart';
import '../models/sales_order_draft/sales_compose_totals.dart';
import 'package:erp/core/formatting/money_formatter.dart';
import 'sales_amount_highlight_row.dart';
import 'sales_order_line_row.dart';

/// Danh sách SP đã chọn theo Figma SG-02:
/// flat order rows trong **một grouped surface** + thẻ tóm tắt thanh toán.
///
/// Không bọc [Padding] thêm trong [VCard] — VCard đã có inset mặc định.
class SalesComposeLinesSection extends StatelessWidget {
  const SalesComposeLinesSection({
    super.key,
    required this.lines,
    required this.onQuantityChanged,
    required this.onDiscount,
    required this.onDelete,
    this.onLineTap,
    this.onStockExceeded,
    required this.totals,
  });

  final List<SalesComposeLineVm> lines;
  final String? Function(String lineId, int quantity) onQuantityChanged;
  final ValueChanged<SalesComposeLineVm> onDiscount;
  final ValueChanged<SalesComposeLineVm> onDelete;

  /// Bấm vùng tên/giá — chọn lại đơn vị bán.
  final ValueChanged<SalesComposeLineVm>? onLineTap;

  /// T-02 — gọi khi nhập/đổi SL vượt tồn khả dụng.
  final VoidCallback? onStockExceeded;

  /// Tóm tắt thanh toán từ pricing preview — không tính lại trong widget.
  final SalesComposeTotals totals;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    if (lines.isEmpty) {
      return const SizedBox.expand(
        child: SalesComposeLinesEmptyState(),
      );
    }

    return ListView(
      children: [
        VCard(
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(VRadius.card),
            child: Column(
              children: [
                for (var i = 0; i < lines.length; i++) ...[
                  if (i > 0) Divider(height: 1, thickness: 1, color: colors.borderDefault),
                  SalesOrderLineRow(
                    key: Key('row_compose_line_${lines[i].identity.lineId}'),
                    productName: lines[i].identity.productName,
                    unitPriceLabel: lines[i].unitPriceLabel,
                    quantity: lines[i].input.quantity,
                    showSpecialPriceBadge: lines[i].hasSpecialPricing,
                    warningText: lines[i].warningText,
                    tone: _toneFor(lines[i].warningLevel),
                    minQuantity: 1,
                    maxQuantity: lines[i].maxQuantity,
                    onQuantityChanged: (qty) {
                      final err = onQuantityChanged(lines[i].identity.lineId, qty);
                      if (err != null) {
                        onStockExceeded?.call();
                      }
                    },
                    onDiscount: () => onDiscount(lines[i]),
                    onDelete: () => onDelete(lines[i]),
                    onTap: onLineTap == null ? null : () => onLineTap!(lines[i]),
                    onQuantityTap: () async {
                      final raw = await showVNumericKeypadSheet(
                        context: context,
                        mode: VNumericKeypadMode.quantity,
                        title: 'Nhập số lượng',
                        unitLabel: 'Đơn vị: ${lines[i].identity.unitLabel}',
                        initialRaw: '${lines[i].input.quantity}',
                        allowDecimal: false,
                      );
                      if (raw == null) return;
                      final qty = int.tryParse(raw.split('.').first);
                      if (qty == null) return;
                      final err = onQuantityChanged(lines[i].identity.lineId, qty);
                      if (err != null && context.mounted) {
                        onStockExceeded?.call();
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
        const VGap(VSpacing.space2),
        // Một lớp inset: VPagePadding (ngoài) + VCard padding mặc định (trong).
        VCard(
          key: const Key('card_compose_payment_summary'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VText(
                'Tóm tắt thanh toán',
                variant: VTextVariant.headingH4,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const VGap.md(),
              _KvRow(
                label: 'Tổng tiền hàng (${totals.itemCount} sản phẩm)',
                value: MoneyFormatter.formatMinor(totals.merchandiseAmountMinor),
              ),
              const VGap.xs(),
              _KvRow(
                label: 'Giảm giá',
                value: totals.discountMinor > 0
                    ? '-${MoneyFormatter.formatMinor(totals.discountMinor)}'
                    : MoneyFormatter.formatMinor(0),
                valueColor: totals.discountMinor > 0 ? colors.danger : null,
              ),
              const VGap.md(),
              SalesAmountHighlightRow(
                label: 'Thành tiền',
                amountMinor: totals.netAmountMinor,
                tone: VComponentTone.primary,
                amountVariant: VTextVariant.headingH4Mono,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static VComponentTone _toneFor(SalesStockWarningLevel level) {
    return switch (level) {
      SalesStockWarningLevel.critical || SalesStockWarningLevel.out => VComponentTone.danger,
      SalesStockWarningLevel.low => VComponentTone.warning,
      SalesStockWarningLevel.none => VComponentTone.neutral,
    };
  }
}

class SalesComposeLinesEmptyState extends StatelessWidget {
  const SalesComposeLinesEmptyState({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return VEmptyState(
      bordered: true,
      backgroundColor: colors.surface,
      child: const VEmptyHeader(
        children: [
          VEmptyMedia(icon: VIcons.info),
          VEmptyTitle('Chưa có sản phẩm trong đơn'),
          VEmptyDescription('Tìm hoặc quét mã để thêm sản phẩm.'),
        ],
      ),
    );
  }
}

class _KvRow extends StatelessWidget {
  const _KvRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: VText(
            label,
            variant: VTextVariant.bodySmallMono,
            color: colors.textSecondary,
          ),
        ),
        VText(
          value,
          variant: VTextVariant.bodyDefaultMono,
          color: valueColor ?? colors.textPrimary,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
