import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

ListView previewList(List<Widget> children) {
  return ListView(
    padding: const EdgeInsets.all(VSpacing.space4),
    children: children,
  );
}

Widget auditStatusBadge(BuildContext context, String label) {
  final colors = context.vColors;
  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: VSpacing.space2,
      vertical: VSpacing.space1,
    ),
    decoration: BoxDecoration(
      color: colors.surfaceAlt,
      borderRadius: BorderRadius.circular(VRadius.r8),
      border: Border.all(color: colors.borderDefault),
    ),
    child: Text(
      label,
      style: VTypography.caption.copyWith(
        color: colors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
