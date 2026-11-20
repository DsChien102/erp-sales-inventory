import 'package:flutter/material.dart';
import 'package:c45_design_system/design_system.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/logic/goods_receipt/receipt_draft.dart';
import 'package:erp/features/inventory/logic/supplier_program/receipt_hint_rules.dart';

class ReceiptOfferBlock extends StatelessWidget {
  const ReceiptOfferBlock({
    super.key,
    required this.line,
    required this.hintsLoading,
    required this.onChanged,
  });

  final ReceiptLineDraft line;
  final bool hintsLoading;
  final ValueChanged<ReceiptLineDraft> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final hint = line.hint;

    // Kiểm tra lỗi SL tặng
    final freeError = line.freeQty >= line.totalQuantity && line.totalQuantity > 0
        ? 'SL tặng phải nhỏ hơn số lượng nhận'
        : null;

    // Kiểm tra lỗi % bậc
    final tierError = line.tierPercent != null &&
            (line.tierPercent! < 0 || line.tierPercent! > 100)
        ? 'Mức giảm từ 0 đến 100%'
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Ưu đãi nhà cung cấp',
          style: VTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: VSpacing.space2),
        if (hintsLoading) ...[
          const VSkeleton(height: 48, width: double.infinity),
          const SizedBox(height: VSpacing.space2),
        ] else if (hint != null) ...[
          VBanner(
            tone: VComponentTone.info,
            title: hint.programName,
            description: [
              ...hintLines(
                hint,
                line.product.baseUom,
                paidQty: line.paidQuantity * line.unit.rate,
              ),
              ...rebateEstimateLines(
                hint,
                line.rebatePercent,
                line.product.baseUom,
                paidQty: line.paidQuantity * line.unit.rate,
                unitPrice: line.unit.rate > 0
                    ? line.unitPriceVnd / line.unit.rate
                    : line.unitPriceVnd,
              ),
            ].join('\n'),
          ),
          const SizedBox(height: VSpacing.space2),
        ],
        if (hint?.kind == ProgramKind.tierDiscount) ...[
          VField(
            invalid: tierError != null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const VFieldLabel('% giảm theo bậc'),
                const SizedBox(height: VSpacing.space1),
                VNumberField(
                  value: line.tierPercent,
                  suffixText: '%',
                  allowDecimal: true,
                  onChanged: (val) {
                    onChanged(
                      line.copyWith(
                        tierPercent: val?.toDouble(),
                        tierEdited: true,
                      ),
                    );
                  },
                ),
                if (tierError != null) ...[
                  const SizedBox(height: VSpacing.space1),
                  VFieldError(tierError),
                ],
              ],
            ),
          ),
          const SizedBox(height: VSpacing.space2),
        ],
        VField(
          invalid: freeError != null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const VFieldLabel('SL tặng'),
              const SizedBox(height: VSpacing.space1),
              VNumberField(
                value: line.freeQty,
                suffixText: line.unit.name,
                onChanged: (val) {
                  onChanged(
                    line.copyWith(
                      freeQty: val ?? 0,
                      freeEdited: true,
                    ),
                  );
                },
              ),
              const SizedBox(height: VSpacing.space1),
              if (freeError != null)
                VFieldError(freeError)
              else
                const VFieldDescription('Gồm trong số lượng nhận ở trên.'),
            ],
          ),
        ),
      ],
    );
  }
}
