import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Sheet xác nhận Tạm ngừng tổ chức (PA-O-03).
class OrganizationSuspendConfirmationBottomSheet extends StatefulWidget {
  final ValueChanged<String>? onConfirm;

  const OrganizationSuspendConfirmationBottomSheet({
    super.key,
    this.onConfirm,
  });

  @override
  State<OrganizationSuspendConfirmationBottomSheet> createState() =>
      _OrganizationSuspendConfirmationBottomSheetState();
}

class _OrganizationSuspendConfirmationBottomSheetState
    extends State<OrganizationSuspendConfirmationBottomSheet> {
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return Padding(
      padding: const EdgeInsets.only(
        left: VSpacing.space4,
        right: VSpacing.space4,
        top: VSpacing.space2,
        bottom: VSpacing.space6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VText(
            'Tạm ngừng tổ chức?',
            variant: VTextVariant.headingH3,
            style: TextStyle(
              color: colors.danger,
              fontWeight: FontWeight.w700,
            ),
          ),
          const VGap.xs(),
          VText(
            'Mọi nghiệp vụ trong tổ chức sẽ bị chặn. Dữ liệu và lịch sử vẫn được giữ lại.',
            variant: VTextVariant.bodyDefault,
            color: colors.textSecondary,
          ),
          const VGap.md(),
          VTextField(
            controller: _reasonController,
            label: 'Lý do',
            hintText: 'Nhập lý do',
            helperText: 'Lý do được lưu trong lịch sử quản trị.',
          ),
          const VGap.lg(),
          VButton(
            label: 'Quay lại',
            variant: VButtonVariant.outline,
            fullWidth: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const VGap.sm(),
          VButton(
            label: 'Tạm ngừng',
            variant: VButtonVariant.dangerOutline,
            fullWidth: true,
            onPressed: () {
              Navigator.of(context).pop();
              widget.onConfirm?.call(_reasonController.text);
            },
          ),
        ],
      ),
    );
  }
}
