import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Sheet xác nhận Đóng tổ chức (terminal, không khôi phục).
class OrganizationCloseConfirmationBottomSheet extends StatefulWidget {
  final ValueChanged<String>? onConfirm;

  const OrganizationCloseConfirmationBottomSheet({
    super.key,
    this.onConfirm,
  });

  @override
  State<OrganizationCloseConfirmationBottomSheet> createState() =>
      _OrganizationCloseConfirmationBottomSheetState();
}

class _OrganizationCloseConfirmationBottomSheetState
    extends State<OrganizationCloseConfirmationBottomSheet> {
  final TextEditingController _reasonController = TextEditingController();
  bool _canSubmit = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) return;
    Navigator.of(context).pop();
    widget.onConfirm?.call(reason);
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
            'Đóng tổ chức?',
            variant: VTextVariant.headingH3,
            style: TextStyle(
              color: colors.danger,
              fontWeight: FontWeight.w700,
            ),
          ),
          const VGap.xs(),
          VText(
            'Tổ chức sẽ ngừng hoạt động vĩnh viễn và không thể khôi phục. Dữ liệu và lịch sử vẫn được giữ để tra cứu.',
            variant: VTextVariant.bodyDefault,
            color: colors.textSecondary,
          ),
          VField(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const VFieldLabel('Lý do đóng'),
                VTextField(
                  controller: _reasonController,
                  hintText: 'Nhập lý do đóng tổ chức',
                  onChanged: (v) => setState(() => _canSubmit = v.trim().isNotEmpty),
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
            label: 'Đóng tổ chức',
            variant: VButtonVariant.secondary,
            tone: VComponentTone.danger,
            fullWidth: true,
            onPressed: _canSubmit ? _submit : null,
          ),
        ],
      ),
    );
  }
}
