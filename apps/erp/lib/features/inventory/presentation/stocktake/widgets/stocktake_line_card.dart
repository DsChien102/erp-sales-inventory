import 'package:erp/features/inventory/data/stocktake/stocktake_models.dart';
import 'package:erp/features/inventory/logic/stocktake/stocktake_rules.dart';
import 'package:erp/features/inventory/presentation/patterns/k7_edit_cell.dart';
import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Thẻ một dòng đếm mù trên mobile (SCR-044); tuyệt đối không hiển thị số sổ.
class StocktakeLineCard extends StatelessWidget {
  const StocktakeLineCard({
    super.key,
    required this.line,
    required this.value,
    required this.focusNode,
    this.errorText,
    required this.onChanged,
    required this.onSubmitted,
  });

  final StocktakeLine line;
  final String value;
  final FocusNode focusNode;
  final String? errorText;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  line.productName,
                  style: VTypography.bodyDefault.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stocktakeLineSub(line),
                  style: VTypography.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                if (line.isUnexpected) ...[
                  const SizedBox(height: VSpacing.space1),
                  const VBadge(
                    label: 'Hàng thực tế',
                    tone: VComponentTone.info,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: VSpacing.space3),
          SizedBox(
            width: 132,
            child: K7EditCell(
              value: value,
              unit: line.uom,
              allowDecimal: true,
              textInputAction: TextInputAction.next,
              focusNode: focusNode,
              errorText: errorText,
              semanticLabel: 'Số lượng thực tế — ${line.productName}',
              onChanged: onChanged,
              onSubmitted: onSubmitted,
            ),
          ),
        ],
      ),
    );
  }
}

