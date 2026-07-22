import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Blocking warning shown when transform step-one validation fails.
class PartnerTransformBlockingBanner extends StatelessWidget {
  const PartnerTransformBlockingBanner({
    super.key,
    this.message = 'Không thể chuyển đổi khi thiếu thông tin bắt buộc hoặc dữ liệu bị trùng.',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Container(
      key: const Key('transform_blocking_banner'),
      padding: const EdgeInsets.all(VSpacing.space3),
      decoration: BoxDecoration(
        color: colors.warningBg,
        borderRadius: BorderRadius.circular(VRadius.card),
        border: Border.all(color: colors.warning.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const VIcon(
            icon: VIcons.warning,
            color: VColors.warning,
            size: 22,
          ),
          const SizedBox(width: VSpacing.space2),
          Expanded(
            child: VText(
              message,
              style: VTypography.bodySmall.copyWith(
                color: colors.textPrimary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
