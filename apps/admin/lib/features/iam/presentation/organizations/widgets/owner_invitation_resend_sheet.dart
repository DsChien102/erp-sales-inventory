import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

/// Sheet thứ hai — xác nhận gửi lại Owner Invitation (PA-SG-02).
///
/// Trả email đã trim/lowercase khi gửi thành công; `null` khi Hủy.
class OwnerInvitationResendSheet extends StatefulWidget {
  const OwnerInvitationResendSheet({
    super.key,
    required this.initialEmail,
    required this.onSubmit,
  });

  final String initialEmail;
  final Future<bool> Function(String email) onSubmit;

  @override
  State<OwnerInvitationResendSheet> createState() => _OwnerInvitationResendSheetState();
}

class _OwnerInvitationResendSheetState extends State<OwnerInvitationResendSheet> {
  late final TextEditingController _emailController;
  var _submitting = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
    _emailController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final email = _emailController.text.trim();
    return !_submitting && email.isNotEmpty && VEmailValidator.isValid(email);
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final email = _emailController.text.trim().toLowerCase();
    setState(() => _submitting = true);
    final ok = await widget.onSubmit(email);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(email);
      return;
    }
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Padding(
      padding: const EdgeInsets.all(VSpacing.screenMobile),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VText(
            'Gửi lại email thiết lập?',
            variant: VTextVariant.headingH3,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const VGap.sm(),
          VText(
            'Liên kết hiện tại sẽ hết hiệu lực. Kiểm tra hoặc cập nhật email trước khi gửi lại.',
            variant: VTextVariant.bodyDefault,
            color: colors.textSecondary,
          ),
          const VGap.lg(),
          VText(
            'Email nhận liên kết',
            variant: VTextVariant.bodyDefault,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const VGap.sm(),
          VTextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            enabled: !_submitting,
            hintText: 'email@example.com',
          ),
          const VGap.xs(),
          VText(
            'Có thể sửa email trước khi gửi lại.',
            variant: VTextVariant.bodySmall,
            color: colors.textSecondary,
          ),
          const VGap.xl(),
          VButton(
            label: 'Gửi',
            isLoading: _submitting,
            onPressed: _canSubmit ? _submit : null,
          ),
          const VGap.sm(),
          VButton(
            label: 'Hủy',
            variant: VButtonVariant.secondary,
            onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
