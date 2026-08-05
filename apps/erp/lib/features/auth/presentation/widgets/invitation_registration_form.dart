import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';

/// ID-D-02 — Trang Kích hoạt tài khoản cho người được mời chưa có tài khoản.
///
/// Layout giữ nguyên thiết kế gốc (banner + 6 field + bottom bar); dữ liệu lấy
/// từ [InvitationTokenInspectionDto] của backend — email khoá theo lời mời.
class InvitationRegistrationForm extends StatefulWidget {
  const InvitationRegistrationForm({
    super.key,
    required this.inspection,
    required this.isSubmitting,
    required this.onRegister,
    required this.onDecline,
    this.onBack,
  });

  final InvitationTokenInspectionDto inspection;
  final bool isSubmitting;
  final Future<void> Function({
    required String givenName,
    required String familyName,
    String? phone,
    required String password,
  }) onRegister;
  final Future<void> Function() onDecline;
  final VoidCallback? onBack;

  @override
  State<InvitationRegistrationForm> createState() =>
      _InvitationRegistrationFormState();
}

class _InvitationRegistrationFormState
    extends State<InvitationRegistrationForm> {
  late final TextEditingController _emailController;
  final _givenNameController = TextEditingController();
  final _familyNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _givenNameError;
  String? _familyNameError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: widget.inspection.inviteeEmail,
    );
  }

  @override
  void dispose() {
    _passwordController.clear();
    _confirmPasswordController.clear();
    _emailController.dispose();
    _givenNameController.dispose();
    _familyNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    final given = _givenNameController.text.trim();
    final family = _familyNameController.text.trim();
    final passwordError = VPasswordValidator.validate(
      _passwordController.text,
      isRequired: true,
      minLength: 1,
    );

    String? confirmPasswordError;
    if (_confirmPasswordController.text.isEmpty) {
      confirmPasswordError = 'Vui lòng nhập lại mật khẩu';
    } else if (_confirmPasswordController.text != _passwordController.text) {
      confirmPasswordError = 'Mật khẩu xác nhận không khớp';
    }

    setState(() {
      _givenNameError = given.isEmpty ? 'Vui lòng nhập tên' : null;
      _familyNameError = family.isEmpty ? 'Vui lòng nhập họ và tên đệm' : null;
      _passwordError = passwordError;
      _confirmPasswordError = confirmPasswordError;
    });

    final hasError = _givenNameError != null ||
        _familyNameError != null ||
        _passwordError != null ||
        _confirmPasswordError != null;

    if (hasError) {
      VToast.show(
        context,
        title: 'Thông tin chưa hợp lệ',
        message: 'Vui lòng kiểm tra và điền đầy đủ các trường bắt buộc',
        type: VToastType.danger,
      );
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (!_validateForm()) return;

    final phone = _phoneController.text.trim();
    await widget.onRegister(
      givenName: _givenNameController.text.trim(),
      familyName: _familyNameController.text.trim(),
      phone: phone.isEmpty ? null : phone,
      password: _passwordController.text,
    );
    if (mounted) {
      _passwordController.clear();
      _confirmPasswordController.clear();
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
              variant: VButtonVariant.outline,
              fullWidth: true,
              onPressed: () => Navigator.of(context).pop(false),
            ),
            const VGap.sm(),
            VButton(
              key: const Key('invitation_decline_submit'),
              label: 'Từ chối lời mời',
              variant: VButtonVariant.dangerOutline,
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
    final inspection = widget.inspection;
    final isSubmitting = widget.isSubmitting;

    return VPageScaffold(
      title: 'Kích hoạt tài khoản',
      leading: widget.onBack == null
          ? null
          : IconButton(
              icon: VIcon(
                icon: VIcons.arrowLeft,
                color: context.vColors.textPrimary,
              ),
              onPressed: isSubmitting ? null : widget.onBack,
            ),
      body: VContentWidth(
        maxWidth: const VResponsiveValue<double>(
          mobile: 500,
          tablet: 500,
          desktop: 500,
        ),
        child: SingleChildScrollView(
          child: VPagePadding(
            horizontal: VSpacing.screenMobile,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const VGap.lg(),
                VBanner(
                  status: VBannerStatus.success,
                  title: 'Mã lời mời hợp lệ',
                  description:
                      'Kích hoạt tài khoản để tham gia ${inspection.tenantName} '
                      'với vai trò ${inspection.initialRoleLabel}.',
                ),
                const VGap.xl(),

                // Field 1: Họ và tên đệm
                VTextField(
                  key: const Key('invitation_register_family_name'),
                  controller: _familyNameController,
                  label: 'Họ và tên đệm',
                  isRequired: true,
                  hintText: 'Nhập họ và tên đệm',
                  enabled: !isSubmitting,
                  errorText: _familyNameError,
                  onChanged: (_) {
                    if (_familyNameError != null) {
                      setState(() => _familyNameError = null);
                    }
                  },
                ),
                const VGap.md(),

                // Field 2: Tên
                VTextField(
                  key: const Key('invitation_register_given_name'),
                  controller: _givenNameController,
                  label: 'Tên',
                  isRequired: true,
                  hintText: 'Nhập tên',
                  enabled: !isSubmitting,
                  errorText: _givenNameError,
                  onChanged: (_) {
                    if (_givenNameError != null) {
                      setState(() => _givenNameError = null);
                    }
                  },
                ),
                const VGap.md(),

                // Field 3: Email (khoá theo lời mời)
                VEmailField(
                  key: const Key('invitation_locked_email'),
                  controller: _emailController,
                  label: 'Email',
                  enabled: false,
                ),
                const VGap.md(),

                // Field 4: Số điện thoại
                VTextField(
                  key: const Key('invitation_register_phone'),
                  controller: _phoneController,
                  label: 'Số điện thoại',
                  hintText: 'Nhập số điện thoại',
                  keyboardType: TextInputType.phone,
                  enabled: !isSubmitting,
                ),
                const VGap.md(),

                // Field 5: Mật khẩu
                VPasswordField(
                  key: const Key('invitation_register_password'),
                  controller: _passwordController,
                  label: 'Mật khẩu',
                  isRequired: true,
                  hintText: 'Nhập mật khẩu',
                  minLength: 1,
                  enabled: !isSubmitting,
                  errorText: _passwordError,
                  onChanged: (_) {
                    if (_passwordError != null) {
                      setState(() => _passwordError = null);
                    }
                  },
                ),
                const VGap.md(),

                // Field 6: Xác nhận mật khẩu
                VPasswordField(
                  key: const Key('invitation_register_confirm_password'),
                  controller: _confirmPasswordController,
                  label: 'Xác nhận mật khẩu',
                  isRequired: true,
                  hintText: 'Nhập lại mật khẩu',
                  minLength: 1,
                  enabled: !isSubmitting,
                  errorText: _confirmPasswordError,
                  onChanged: (_) {
                    if (_confirmPasswordError != null) {
                      setState(() => _confirmPasswordError = null);
                    }
                  },
                  onSubmitted: (_) => _submit(),
                ),
                const VGap.xl(),
              ],
            ),
          ),
        ),
      ),
      bottomBar: Padding(
        padding: const EdgeInsets.all(VSpacing.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            VButton(
              key: const Key('invitation_accept_submit'),
              label: 'Kích hoạt tài khoản',
              fullWidth: true,
              isLoading: isSubmitting,
              onPressed: isSubmitting ? null : _submit,
            ),
            const VGap.sm(),
            VButton(
              label: 'Từ chối lời mời',
              variant: VButtonVariant.outline,
              fullWidth: true,
              onPressed: isSubmitting ? null : _decline,
            ),
          ],
        ),
      ),
    );
  }
}
