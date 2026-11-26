import 'package:c45_design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Hộp cảnh báo nền vàng dùng trong khối Hồ sơ pháp lý và sheet trùng MST.
class LegalNoticeBox extends StatelessWidget {
  const LegalNoticeBox({
    super.key,
    required this.title,
    required this.message,
    this.compact = false,
  });

  final String title;
  final String message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Container(
      padding: EdgeInsets.all(compact ? VSpacing.space3 : VSpacing.space4),
      decoration: BoxDecoration(
        color: colors.warningBg,
        borderRadius: BorderRadius.circular(
          compact ? VRadius.input : VRadius.card,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VIcon(
            icon: VIcons.warning,
            size: 20,
            color: colors.warning,
          ),
          const VGap.horizontalSm(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VText(
                  title,
                  variant: VTextVariant.bodyDefault,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: colors.warning,
                  ),
                ),
                if (!compact) const VGap.xs(),
                VText(
                  message,
                  variant: VTextVariant.bodySmall,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
