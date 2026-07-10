import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Dark success toast shown after creating a partner (D-10 / VD-09).
void showPartnerCreateSuccessToast(BuildContext context) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const _PartnerCreateSuccessToast(),
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
    ),
  );
}

class _PartnerCreateSuccessToast extends StatelessWidget {
  const _PartnerCreateSuccessToast();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('toast_partner_create_success'),
      margin: const EdgeInsets.symmetric(
        horizontal: VSpacing.space4,
        vertical: VSpacing.space1,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space4,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: VColors.neutral900,
        borderRadius: BorderRadius.circular(VRadius.r16),
        boxShadow: VShadows.e2,
        border: Border.all(color: VColors.neutral0.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: VColors.success,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.check_rounded,
              color: VColors.neutral0,
              size: 14,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đã tạo KH & NCC thành công',
                  style: VTypography.bodyDefault.copyWith(
                    color: VColors.neutral0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Hồ sơ đã được tạo mới.',
                  style: VTypography.bodySmall.copyWith(
                    color: VColors.neutral0.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            child: Icon(
              Icons.close_rounded,
              color: VColors.neutral0.withValues(alpha: 0.54),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
