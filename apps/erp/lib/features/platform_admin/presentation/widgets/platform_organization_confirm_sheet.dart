import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// C4 — sheet xác nhận Tạm ngừng / Khôi phục / Đóng.
///
/// [reasonLabel] `null` = không có ô lý do (Khôi phục: RPC không nhận lý do).
/// Có ô lý do thì bắt buộc; để trống → "Vui lòng nhập lý do.".
class PlatformOrganizationConfirmSheet extends StatefulWidget {
  const PlatformOrganizationConfirmSheet({
    super.key,
    required this.title,
    required this.description,
    required this.confirmLabel,
    required this.onConfirm,
    this.reasonLabel,
    this.reasonHint = 'Nhập lý do',
    this.isDanger = true,
  });

  /// Tạm ngừng tổ chức?
  factory PlatformOrganizationConfirmSheet.suspend({
    Key? key,
    required ValueChanged<String?> onConfirm,
  }) {
    return PlatformOrganizationConfirmSheet(
      key: key,
      title: 'Tạm ngừng tổ chức?',
      description:
          'Mọi nghiệp vụ trong tổ chức sẽ bị chặn. Dữ liệu và lịch sử vẫn được giữ lại.',
      reasonLabel: 'Lý do',
      confirmLabel: 'Tạm ngừng',
      onConfirm: onConfirm,
    );
  }

  /// Khôi phục tổ chức?
  factory PlatformOrganizationConfirmSheet.restore({
    Key? key,
    required ValueChanged<String?> onConfirm,
  }) {
    return PlatformOrganizationConfirmSheet(
      key: key,
      title: 'Khôi phục tổ chức?',
      description:
          'Thành viên có thể tiếp tục vận hành theo quyền hiện hành sau khi khôi phục.',
      confirmLabel: 'Khôi phục',
      isDanger: false,
      onConfirm: onConfirm,
    );
  }

  /// Đóng tổ chức?
  factory PlatformOrganizationConfirmSheet.close({
    Key? key,
    required ValueChanged<String?> onConfirm,
  }) {
    return PlatformOrganizationConfirmSheet(
      key: key,
      title: 'Đóng tổ chức?',
      description:
          'Tổ chức sẽ chuyển sang chỉ đọc vĩnh viễn và không thể khôi phục.',
      reasonLabel: 'Lý do đóng',
      reasonHint: 'Nhập lý do đóng tổ chức',
      confirmLabel: 'Đóng tổ chức',
      onConfirm: onConfirm,
    );
  }

  final String title;
  final String description;
  final String confirmLabel;
  final String? reasonLabel;
  final String reasonHint;
  final bool isDanger;

  /// Nhận lý do đã cắt khoảng trắng; `null` khi không có ô lý do.
  final ValueChanged<String?> onConfirm;

  @override
  State<PlatformOrganizationConfirmSheet> createState() =>
      _PlatformOrganizationConfirmSheetState();
}

class _PlatformOrganizationConfirmSheetState extends State<PlatformOrganizationConfirmSheet> {
  final TextEditingController _reasonController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.reasonLabel == null) {
      Navigator.of(context).pop();
      widget.onConfirm(null);
      return;
    }
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() => _error = 'Vui lòng nhập lý do.');
      return;
    }
    Navigator.of(context).pop();
    widget.onConfirm(reason);
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
            widget.title,
            variant: VTextVariant.headingH3,
            style: TextStyle(
              color: widget.isDanger ? colors.danger : colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const VGap.xs(),
          VText(
            widget.description,
            variant: VTextVariant.bodyDefault,
            color: colors.textSecondary,
          ),
          if (widget.reasonLabel != null) ...[
            const VGap.md(),
            VField(
              invalid: _error != null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VFieldLabel('${widget.reasonLabel} *'),
                  VTextField(
                    controller: _reasonController,
                    hintText: widget.reasonHint,
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                  ),
                  if (_error != null)
                    VFieldError(_error!)
                  else
                    const VFieldDescription('Lý do được lưu trong lịch sử quản trị.'),
                ],
              ),
            ),
          ],
          const VGap.lg(),
          VButton(
            label: 'Quay lại',
            variant: VButtonVariant.secondary,
            fullWidth: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const VGap.sm(),
          VButton(
            key: const Key('platform_confirm_submit'),
            label: widget.confirmLabel,
            variant: widget.isDanger ? VButtonVariant.secondary : VButtonVariant.primary,
            tone: widget.isDanger ? VComponentTone.danger : VComponentTone.success,
            fullWidth: true,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
