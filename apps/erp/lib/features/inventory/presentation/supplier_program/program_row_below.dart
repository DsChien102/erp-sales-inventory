import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/logic/supplier_program/supplier_program_rules.dart';
import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class ProgramRowBelow extends StatelessWidget {
  final ProgramRow row;

  const ProgramRowBelow(this.row, {super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    if (row.kind == ProgramKind.volumeRebate) {
      final target = (row.targetQty ?? 0).toDouble();
      final progress = row.progressQty.toDouble();
      final ratio = target > 0 ? (progress / target).clamp(0.0, 1.0) : 0.0;
      final u = (row.commonUom != null && row.commonUom!.trim().isNotEmpty)
          ? ' ${row.commonUom!.trim()}'
          : '';
      final progressText =
          '${formatProgramQuantity(row.progressQty)} / ${formatProgramQuantity(row.targetQty ?? 0)}$u';

      return Row(
        children: [
          Expanded(
            child: VProgress(
              value: ratio,
              height: 6,
              animated: false,
            ),
          ),
          const SizedBox(width: VSpacing.space2),
          VText(
            progressText,
            variant: VTextVariant.bodySmallMono,
            color: colors.textSecondary,
          ),
        ],
      );
    }

    return VText(
      programSummary(row),
      variant: VTextVariant.bodySmall,
      color: colors.textSecondary,
    );
  }
}
