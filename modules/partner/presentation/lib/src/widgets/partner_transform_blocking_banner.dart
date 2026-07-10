import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Blocking warning shown when transform step-one validation fails.
class PartnerTransformBlockingBanner extends StatelessWidget {
  const PartnerTransformBlockingBanner({
    super.key,
    this.message =
        'Không thể chuyển đổi khi thiếu thông tin bắt buộc hoặc dữ liệu bị trùng.',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('transform_blocking_banner'),
      padding: const EdgeInsets.all(VSpacing.space3),
      decoration: BoxDecoration(
        color: VColors.warningBg,
        borderRadius: BorderRadius.circular(VRadius.card),
        border: Border.all(color: VColors.warning.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: VColors.warning,
            size: 22,
          ),
          const SizedBox(width: VSpacing.space2),
          Expanded(
            child: Text(
              message,
              style: VTypography.bodySmall.copyWith(
                color: context.vColors.textPrimary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
