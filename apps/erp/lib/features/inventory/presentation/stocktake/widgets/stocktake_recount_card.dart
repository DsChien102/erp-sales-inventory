import 'package:erp/features/inventory/data/stocktake/stocktake_models.dart';
import 'package:erp/features/inventory/logic/inventory_format.dart';
import 'package:erp/features/inventory/logic/stocktake/stocktake_rules.dart';
import 'package:erp/features/inventory/presentation/patterns/k7_edit_cell.dart';
import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Nhãn các lựa chọn lý do thiếu hàng dùng chung cho card mobile và bảng web (SCR-045).
const List<String> stocktakeLossReasonLabels = ['Thất thoát', 'Hỏng', 'Hết hạn'];

/// Thẻ một dòng cần đếm lại trên mobile (SCR-045).
class StocktakeRecountCard extends StatelessWidget {
  const StocktakeRecountCard({
    super.key,
    required this.line,
    required this.value,
    required this.focusNode,
    this.reason,
    required this.onChanged,
    required this.onSubmitted,
    required this.onApplySame,
    this.onReasonChanged,
  });

  final StocktakeLine line;
  final String value;
  final FocusNode focusNode;
  final StocktakeLossReason? reason;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onApplySame;
  final ValueChanged<StocktakeLossReason>? onReasonChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final variance = line.variance ?? 0;
    final firstQty = line.firstQty ?? 0;
    final bookQty = line.bookQty ?? 0;
    final title = line.lotCode != null
        ? '${line.productName} · Lô ${line.lotCode}'
        : line.productName;

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: VSpacing.space3,
        horizontal: VSpacing.space4,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(VRadius.card),
        border: VBorders.all(colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: VTypography.bodyDefault.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Theo sổ ${formatStockQuantity(bookQty, line.uom)} · Đếm đầu ${formatStockQuantity(firstQty, line.uom)}',
                      style: VTypography.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: VSpacing.space2),
              VBadge(
                label: varianceLabel(variance, line.uom),
                tone: VComponentTone.warning,
              ),
            ],
          ),
          const SizedBox(height: VSpacing.space3),
          Row(
            children: [
              Expanded(
                child: K7EditCell(
                  value: value,
                  unit: line.uom,
                  allowDecimal: true,
                  maxWidth: double.infinity,
                  textInputAction: TextInputAction.next,
                  focusNode: focusNode,
                  semanticLabel: 'Số lượng đếm lại — ${line.productName}',
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                ),
              ),
              const SizedBox(width: VSpacing.space2),
              VButton(
                label: 'Vẫn ${formatStockQuantity(firstQty, line.uom)}',
                variant: VButtonVariant.secondary,
                onPressed: onApplySame,
              ),
            ],
          ),
          if (variance < 0 && reason != null && onReasonChanged != null) ...[
            const SizedBox(height: VSpacing.space2),
            Text(
              'Lý do',
              style: VTypography.caption.copyWith(
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: VSpacing.space1),
            VSegmentedControl(
              segments: stocktakeLossReasonLabels,
              selectedIndex: reason!.index,
              onChanged: (idx) =>
                  onReasonChanged!(StocktakeLossReason.values[idx]),
            ),
          ],
        ],
      ),
    );
  }
}

