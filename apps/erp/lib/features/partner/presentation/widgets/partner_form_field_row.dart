import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

class PartnerFormFieldRow extends StatelessWidget {
  const PartnerFormFieldRow({
    super.key,
    required this.label,
    required this.field,
    this.isRequired = false,
    this.errorText,
    this.alignFieldTop = false,
    this.dense = false,
    this.labelWidth = labelWidthDefault,
    this.labelFieldGap = labelFieldGapDefault,
  });

  final String label;
  final Widget field;
  final bool isRequired;
  final String? errorText;
  final bool alignFieldTop;
  final bool dense;
  final double labelWidth;
  final double labelFieldGap;

  static const double labelWidthDefault = 104;
  static const double labelFieldGapDefault = 28;
  static const double contactLabelWidth = 88;
  static const double contactLabelFieldGap = 40;

  /// Shared metrics for invoice + delivery sections (create/edit).
  static const double detailLabelWidth = 120;
  static const double detailLabelFieldGap = 12;

  /// Wide enough for full "Tỉnh / Thành phố" — keep ward row identical.
  static const double deliveryLabelWidth = 136;
  static const double deliveryLabelFieldGap = 12;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: VSpacing.space4,
            vertical: dense ? VSpacing.space1 : VSpacing.space2,
          ),
          child: Row(
            crossAxisAlignment: alignFieldTop
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: labelWidth,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: alignFieldTop ? VSpacing.space2 : 0,
                  ),
                  child: RichText(
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    text: TextSpan(
                      style: VTypography.bodySmall.copyWith(
                        color: colors.textSecondary,
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(text: label),
                        if (isRequired)
                          TextSpan(
                            text: ' *',
                            style: TextStyle(color: colors.danger),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: labelFieldGap),
              Expanded(child: field),
            ],
          ),
        ),
        if (errorText != null) ...[
          Padding(
            padding: EdgeInsets.only(
              left: VSpacing.space4 + labelWidth + labelFieldGap,
              right: VSpacing.space4,
              bottom: VSpacing.space2,
            ),
            child: VText(
              errorText!,
              variant: VTextVariant.bodySmall,
              color: colors.danger,
            ),
          ),
        ],
      ],
    );
  }
}
