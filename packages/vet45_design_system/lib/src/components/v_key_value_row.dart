import 'package:flutter/material.dart';

import '../foundation/v_context_extensions.dart';
import '../primitives/v_text.dart';
import '../tokens/v_borders.dart';
import '../tokens/v_radius.dart';
import '../tokens/v_spacing.dart';
import '../tokens/v_typography.dart';

class VKeyValueRow extends StatelessWidget {
  const VKeyValueRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasized = false,
    this.mono = false,
    this.trailing,
  });

  final String label;
  final String value;
  final bool emphasized;
  final bool mono;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    final labelStyle = VTypography.bodyDefault.copyWith(
      color: colors.textSecondary,
      fontWeight: emphasized ? FontWeight.w600 : FontWeight.w400,
    );

    final valueStyle = mono
        ? VTypography.monoNumeric.copyWith(
            color: emphasized ? colors.textPrimary : colors.textPrimary,
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
          )
        : VTypography.bodyDefault.copyWith(
            color: colors.textPrimary,
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
          );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space3,
        vertical: VSpacing.space2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 2,
            fit: FlexFit.tight,
            child: Text(
              label,
              style: labelStyle,
            ),
          ),
          const SizedBox(width: VSpacing.space2),
          // Giá trị dài (mã tham chiếu, "Tồn kho đã đổi") xuống dòng thay vì tràn.
          Flexible(
            flex: 3,
            fit: FlexFit.tight,
            child: Text(
              value,
              style: valueStyle,
              textAlign: TextAlign.right,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: VSpacing.space2),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class VKeyValueGroup extends StatelessWidget {
  const VKeyValueGroup({
    super.key,
    this.title,
    required this.rows,
  });

  final String? title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(VRadius.card),
        border: VBorders.all(colors.borderDefault),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null && title!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VSpacing.space3,
                VSpacing.space3,
                VSpacing.space3,
                VSpacing.space1,
              ),
              child: VText(
                title!,
                variant: VTextVariant.headingH4,
                color: colors.textPrimary,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                color: colors.borderDefault.withValues(alpha: 0.5),
              ),
          ],
        ],
      ),
    );
  }
}
