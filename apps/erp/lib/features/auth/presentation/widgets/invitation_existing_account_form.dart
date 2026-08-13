import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';

class InvitationExistingAccountForm extends StatefulWidget {
  const InvitationExistingAccountForm({
    super.key,
    required this.inspection,
    required this.isSubmitting,
    required this.onAccept,
    required this.onDecline,
  });

  final InvitationTokenInspectionDto inspection;
  final bool isSubmitting;
  final Future<void> Function(String password) onAccept;
  final Future<void> Function() onDecline;

  @override
  State<InvitationExistingAccountForm> createState() =>
      _InvitationExistingAccountFormState();
}

class _InvitationExistingAccountFormState
    extends State<InvitationExistingAccountForm> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: widget.inspection.inviteeEmail,
    );
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _passwordController.clear();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _accept() async {
    final passwordError = VPasswordValidator.validate(
      _passwordController.text,
      isRequired: true,
      minLength: 1,
    );
    if (passwordError != null) {
      setState(() => _passwordError = passwordError);
      return;
    }
    setState(() => _passwordError = null);
    final password = _passwordController.text;
    await widget.onAccept(password);
    if (mounted) {
      _passwordController.clear();
    }
  }

  Future<void> _decline() async {
    final confirmed = await showVBottomSheet<bool>(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.screenMobile),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const VText(
              'Từ chối lời mời?',
              variant: VTextVariant.headingH3,
            ),
            const VGap.sm(),
            VText(
              'Bạn sẽ không tham gia ${widget.inspection.tenantName}.',
              variant: VTextVariant.bodyDefault,
            ),
            const VGap.lg(),
            VButton(
              label: 'Huỷ',
              variant: VButtonVariant.secondary,
              fullWidth: true,
              onPressed: () => Navigator.of(context).pop(false),
            ),
            const VGap.sm(),
            VButton(
              key: const Key('invitation_decline_submit'),
              label: 'Từ chối lời mời',
              variant: VButtonVariant.secondary,
              tone: VComponentTone.danger,
              fullWidth: true,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const VGap.sm(),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      await widget.onDecline();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final inspection = widget.inspection;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VText(
          'Đăng nhập để tham gia',
          variant: VTextVariant.headingH3,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const VGap.xs(),
        VText(
          '${inspection.tenantName} · ${inspection.initialRoleLabel}',
          variant: VTextVariant.bodyDefault,
          color: colors.textSecondary,
        ),
        const VGap.lg(),
        VTextField(
          key: const Key('invitation_locked_email'),
          controller: _emailController,
          label: 'Email',
          enabled: false,
        ),
        const VGap.md(),
        VTextField(
          key: const Key('invitation_existing_password'),
          controller: _passwordController,
          label: 'Mật khẩu',
          obscureText: true,
          enabled: !widget.isSubmitting,
          errorText: _passwordError,
          onChanged: (_) {
            if (_passwordError != null) {
              setState(() => _passwordError = null);
            }
          },
        ),
        const VGap.lg(),
        VButton(
          key: const Key('invitation_accept_submit'),
          label: 'Đăng nhập và tham gia',
          fullWidth: true,
          isLoading: widget.isSubmitting,
          onPressed: widget.isSubmitting ? null : _accept,
        ),
        const VGap.sm(),
        VButton(
          label: 'Từ chối lời mời',
          variant: VButtonVariant.secondary,
          fullWidth: true,
          onPressed: widget.isSubmitting ? null : _decline,
        ),
      ],
    );
  }
}
