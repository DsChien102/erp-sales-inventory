import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Confirm revoke with required non-empty reason. Sheet closes only on success.
Future<bool?> showRevokeInvitationBottomSheet({
  required BuildContext context,
  required Future<bool> Function(String reason) onRevoke,
}) {
  return showVBottomSheet<bool>(
    context: context,
    child: _RevokeInvitationSheetBody(onRevoke: onRevoke),
  );
}

class _RevokeInvitationSheetBody extends StatefulWidget {
  const _RevokeInvitationSheetBody({required this.onRevoke});

  final Future<bool> Function(String reason) onRevoke;

  @override
  State<_RevokeInvitationSheetBody> createState() =>
      _RevokeInvitationSheetBodyState();
}

class _RevokeInvitationSheetBodyState extends State<_RevokeInvitationSheetBody> {
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
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() => _localError = 'Vui lòng nhập lý do thu hồi.');
      return;
    }

    setState(() {
      _submitting = true;
      _localError = null;
    });

    final ok = await widget.onRevoke(reason);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _submitting = false;
      _localError = 'Không thu hồi được lời mời. Vui lòng thử lại.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Padding(
      padding: const EdgeInsets.all(VSpacing.screenMobile),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VText(
            'Thu hồi lời mời?',
            variant: VTextVariant.headingH3,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: colors.danger,
            ),
          ),
          const VGap.xs(),
          VText(
            'Người nhận sẽ không thể dùng liên kết hiện tại để tham gia tổ chức.',
            variant: VTextVariant.bodyDefault,
            color: colors.textSecondary,
          ),
          const VGap.md(),
          VTextFormField(
            controller: _reasonController,
            label: 'Lý do thu hồi',
            hintText: 'Ví dụ: Sai email người nhận',
            enabled: !_submitting,
            maxLines: 3,
            errorText: _localError,
            onChanged: (_) {
              if (_localError != null) {
                setState(() => _localError = null);
              }
            },
          ),
          const VGap.lg(),
          VButton(
            label: 'Quay lại',
            variant: VButtonVariant.secondary,
            fullWidth: true,
            onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          ),
          const VGap.sm(),
          VButton(
            label: 'Thu hồi lời mời',
            variant: VButtonVariant.secondary,
            tone: VComponentTone.danger,
            fullWidth: true,
            isLoading: _submitting,
            onPressed: _submitting ? null : _confirm,
          ),
          const VGap.sm(),
        ],
      ),
    );
  }
}
