import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// VBottomSheet Xác nhận chuyển tổ chức.
class ConfirmSwitchOrganizationBottomSheet extends StatelessWidget {
  final String targetOrganizationName;

  const ConfirmSwitchOrganizationBottomSheet({
    super.key,
    required this.targetOrganizationName,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.screenMobile,
        vertical: VSpacing.space4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: VText(
              'Chuyển sang $targetOrganizationName?',
              variant: VTextVariant.headingH3,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const VGap.sm(),
          VText(
            'Dữ liệu và quyền truy cập sẽ được tải lại theo tổ chức đã chọn.',
            variant: VTextVariant.bodyDefault,
            color: colors.textSecondary,
          ),
          const VGap.lg(),
          SizedBox(
            width: double.infinity,
            child: VButton(
              label: 'Quay lại',
              variant: VButtonVariant.secondary,
              tone: VComponentTone.neutral,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ),
          const VGap.sm(),
          SizedBox(
            width: double.infinity,
            child: VButton(
              label: 'Chuyển tổ chức',
              tone: VComponentTone.primary,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ),
          const VGap.md(),
        ],
      ),
    );
  }
}

/// Helper function mở VBottomSheet Xác nhận chuyển tổ chức.
Future<bool?> showConfirmSwitchOrganizationBottomSheet({
  required BuildContext context,
  required String targetOrganizationName,
}) {
  return showVAdaptiveSheet<bool>(
    context: context,
    child: ConfirmSwitchOrganizationBottomSheet(
      targetOrganizationName: targetOrganizationName,
    ),
  );
}
