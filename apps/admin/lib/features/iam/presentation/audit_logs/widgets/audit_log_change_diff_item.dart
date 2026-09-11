import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

import '../models/audit_log_ui_model.dart';

class AuditLogChangeDiffItem extends StatelessWidget {
  const AuditLogChangeDiffItem({
    super.key,
    required this.change,
    this.embedded = false,
  });

  final AuditLogChangeRowUiModel change;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Container(
      padding: embedded ? EdgeInsets.zero : const EdgeInsets.all(VSpacing.space4),
      decoration: embedded
          ? null
          : BoxDecoration(
              color: colors.surfaceAlt,
              borderRadius: BorderRadius.circular(VRadius.card),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VText(
            change.fieldLabel,
            variant: VTextVariant.bodyDefault,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const VGap.xs(),
          VText(
            'Trước: ${change.beforeValue ?? '—'}',
            variant: VTextVariant.bodySmall,
            color: colors.textSecondary,
          ),
          const SizedBox(height: 2),
          VText(
            'Sau: ${change.afterValue ?? '—'}',
            variant: VTextVariant.bodySmall,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
