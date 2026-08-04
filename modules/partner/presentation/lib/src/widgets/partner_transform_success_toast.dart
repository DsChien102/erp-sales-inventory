import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Dark success toast after person → organization transform (SG-05).
void showPartnerTransformSuccessToast(BuildContext context) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const _PartnerTransformSuccessToast(),
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
    ),
  );
}

class _PartnerTransformSuccessToast extends StatelessWidget {
  const _PartnerTransformSuccessToast();

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    // Always-dark toast chrome: textPrimary as dark panel, white foreground.
    return Container(
      key: const Key('toast_partner_transform_success'),
      margin: const EdgeInsets.symmetric(
        horizontal: VSpacing.space4,
        vertical: VSpacing.space1,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.space4,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: colors.textPrimary,
        borderRadius: BorderRadius.circular(VRadius.r16),
        boxShadow: VShadows.e2,
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: colors.success,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(width: VSpacing.space3),
          const Expanded(
            child: VText(
              'Đã chuyển đổi thành công.',
              variant: VTextVariant.bodyDefault,
              color: Colors.white,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            child: Icon(
              Icons.close_rounded,
              color: Colors.white.withValues(alpha: 0.54),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
