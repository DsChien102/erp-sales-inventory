import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';

/// Confirm tenant activation.
Future<bool?> showActivateTenantBottomSheet({
  required BuildContext context,
  required TenantReadinessDto readiness,
  required Future<bool> Function() onActivate,
}) {
  return showVBottomSheet<bool>(
    context: context,
    child: _ActivateTenantSheetBody(
      readiness: readiness,
      onActivate: onActivate,
    ),
  );
}

class _ActivateTenantSheetBody extends StatefulWidget {
  const _ActivateTenantSheetBody({
    required this.readiness,
    required this.onActivate,
  });

  final TenantReadinessDto readiness;
  final Future<bool> Function() onActivate;

  @override
  State<_ActivateTenantSheetBody> createState() => _ActivateTenantSheetBodyState();
}

class _ActivateTenantSheetBodyState extends State<_ActivateTenantSheetBody> {
  late final TextEditingController _reasonController;
  bool _submitting = false;
  String? _localError;

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

  Future<void> _confirm() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _localError = null;
    });
    final ok = await widget.onActivate();
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _submitting = false;
      _localError = 'Không kích hoạt được. Vui lòng thử lại.';
    });
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
            enabled: !_submitting,
          ),
          const VGap.xs(),
          VText(
            'Lý do được lưu trong lịch sử quản trị.',
            variant: VTextVariant.bodySmall,
            color: colors.textSecondary,
          ),
          if (_localError != null) ...[
            const VGap.sm(),
            VText(
              _localError!,
              variant: VTextVariant.bodySmall,
              color: colors.danger,
            ),
          ],
          const VGap.lg(),
          VButton(
            label: 'Để sau',
            variant: VButtonVariant.outline,
            tone: VComponentTone.neutral,
            fullWidth: true,
            onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          ),
          const VGap.sm(),
          VButton(
            label: 'Kích hoạt',
            variant: VButtonVariant.primary,
            tone: VComponentTone.success,
            fullWidth: true,
            isLoading: _submitting,
            onPressed: _submitting ? null : _confirm,
          ),
          const VGap.md(),
        ],
      ),
    );
  }
}
