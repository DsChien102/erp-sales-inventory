import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Sheet xác nhận Khôi phục tổ chức (PA-O-04).
class OrganizationRestoreConfirmationBottomSheet extends StatefulWidget {
  final ValueChanged<String>? onConfirm;

  const OrganizationRestoreConfirmationBottomSheet({
    super.key,
    this.onConfirm,
  });

  @override
  State<OrganizationRestoreConfirmationBottomSheet> createState() =>
      _OrganizationRestoreConfirmationBottomSheetState();
}

class _OrganizationRestoreConfirmationBottomSheetState
    extends State<OrganizationRestoreConfirmationBottomSheet> {
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
            'Khôi phục tổ chức?',
            variant: VTextVariant.headingH3,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const VGap.xs(),
          VText(
            'Thành viên có thể tiếp tục vận hành theo quyền hiện hành sau khi khôi phục.',
            variant: VTextVariant.bodyDefault,
            color: colors.textSecondary,
          ),
          const VGap.md(),
          VField(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const VFieldLabel('Lý do'),
                VTextField(
                  controller: _reasonController,
                  hintText: 'Nhập lý do',
                ),
                const VFieldDescription(
                  'Lý do được lưu trong lịch sử quản trị.',
                ),
              ],
            ),
          ),
          const VGap.lg(),
          VButton(
            label: 'Quay lại',
            variant: VButtonVariant.secondary,
            fullWidth: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const VGap.sm(),
          VButton(
            label: 'Khôi phục',
            variant: VButtonVariant.primary,
            tone: VComponentTone.success,
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
