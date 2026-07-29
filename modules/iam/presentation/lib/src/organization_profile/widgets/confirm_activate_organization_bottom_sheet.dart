import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// VBottomSheet Xác nhận kích hoạt cửa hàng / tổ chức (TA-O-01).
class ConfirmActivateOrganizationBottomSheet extends StatefulWidget {
  const ConfirmActivateOrganizationBottomSheet({super.key});

  @override
  State<ConfirmActivateOrganizationBottomSheet> createState() =>
      _ConfirmActivateOrganizationBottomSheetState();
}

class _ConfirmActivateOrganizationBottomSheetState
    extends State<ConfirmActivateOrganizationBottomSheet> {
  late final TextEditingController _reasonController;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

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
          VText(
            'Kích hoạt tổ chức?',
            variant: VTextVariant.headingH3,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const VGap.sm(),
          VText(
            'Sau khi kích hoạt, thành viên có thể sử dụng các nghiệp vụ theo vai trò và quyền hiện hành.',
            variant: VTextVariant.bodyDefault,
            color: colors.textSecondary,
          ),
          const VGap.md(),
          VText(
            'Lý do',
            variant: VTextVariant.bodySmall,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const VGap.xs(),
          VTextField(
            hintText: 'Nhập lý do',
            controller: _reasonController,
          ),
          const VGap.xs(),
          VText(
            'Lý do được lưu trong lịch sử quản trị.',
            variant: VTextVariant.bodySmall,
            color: colors.textSecondary,
          ),
          const VGap.lg(),
          SizedBox(
            width: double.infinity,
            child: VButton(
              label: 'Để sau',
              variant: VButtonVariant.outline,
              tone: VComponentTone.neutral,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ),
          const VGap.sm(),
          SizedBox(
            width: double.infinity,
            child: VButton(
              label: 'Kích hoạt',
              variant: VButtonVariant.primary,
              tone: VComponentTone.success,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ),
          const VGap.md(),
        ],
      ),
    );
  }
}

/// Helper function mở VBottomSheet Xác nhận kích hoạt tổ chức.
Future<bool?> showConfirmActivateOrganizationBottomSheet({
  required BuildContext context,
}) {
  return showVBottomSheet<bool>(
    context: context,
    child: const ConfirmActivateOrganizationBottomSheet(),
  );
}
