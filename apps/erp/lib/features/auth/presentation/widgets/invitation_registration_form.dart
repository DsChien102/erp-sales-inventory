import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/config/wide_layout.dart';
import 'package:erp/core/validation/password_policy.dart';
import 'package:flutter/material.dart';

import '../../data/models/invitation_token_inspection.dart';
import 'invitation_register_narrow.dart';
import 'invitation_register_wide.dart';

/// ID-D-02 — Trang Kích hoạt tài khoản cho người được mời chưa có tài khoản.
///
/// Layout giữ nguyên thiết kế gốc (banner + 6 field + bottom bar); dữ liệu lấy
/// từ [InvitationTokenInspection] của backend — email khoá theo lời mời.
class InvitationRegistrationForm extends StatefulWidget {
  const InvitationRegistrationForm({
    super.key,
    required this.inspection,
    required this.isSubmitting,
    required this.onRegister,
    this.onBack,
  });

  final InvitationTokenInspection inspection;
  final bool isSubmitting;
  final Future<void> Function({
    required String givenName,
    required String familyName,
    String? phone,
    required String password,
  })
  onRegister;
  final VoidCallback? onBack;

  @override
  State<InvitationRegistrationForm> createState() => _InvitationRegistrationFormState();
}

class _InvitationRegistrationFormState extends State<InvitationRegistrationForm> {
  late final TextEditingController _emailController;
  final _givenNameController = TextEditingController();
  final _familyNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _givenNameError;
  String? _familyNameError;
  String? _phoneError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    final inspection = widget.inspection;
    _emailController = TextEditingController(text: inspection.inviteeEmail);
    if (inspection.givenName != null && inspection.givenName!.isNotEmpty) {
      _givenNameController.text = inspection.givenName!;
    }
    if (inspection.familyName != null && inspection.familyName!.isNotEmpty) {
      _familyNameController.text = inspection.familyName!;
    }
    if (inspection.phone != null && inspection.phone!.isNotEmpty) {
      _phoneController.text = inspection.phone!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _givenNameController.dispose();
    _familyNameController.dispose();
    _phoneController.dispose();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    final given = _givenNameController.text.trim();
    final family = _familyNameController.text.trim();
    final phoneError = VPhoneValidator.validate(
      _phoneController.text,
      isRequired: false,
    );
    final passwordError = PasswordPolicy.validate(_passwordController.text);

    String? confirmPasswordError;
    if (_confirmPasswordController.text.isEmpty) {
      confirmPasswordError = 'Vui lòng nhập lại mật khẩu';
    } else if (_confirmPasswordController.text != _passwordController.text) {
      confirmPasswordError = 'Mật khẩu xác nhận không khớp';
    }

    setState(() {
      _givenNameError = given.isEmpty ? 'Vui lòng nhập tên' : null;
      _familyNameError = family.isEmpty ? 'Vui lòng nhập họ và tên đệm' : null;
      _phoneError = phoneError;
      _passwordError = passwordError;
      _confirmPasswordError = confirmPasswordError;
    });

    final hasError =
        _givenNameError != null ||
        _familyNameError != null ||
        _phoneError != null ||
        _passwordError != null ||
        _confirmPasswordError != null;

    return !hasError;
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

  @override
  Widget build(BuildContext context) {
    final inspection = widget.inspection;
    final isSubmitting = widget.isSubmitting;
    final wide = isWideLayout(context);

    final familyField = VField(
      invalid: _familyNameError != null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const VFieldLabel('Họ và tên đệm', isRequired: true),
          VTextField(
            key: const Key('invitation_register_family_name'),
            controller: _familyNameController,
            hintText: 'Nhập họ và tên đệm',
            enabled: !isSubmitting,
            autofillHints: const [AutofillHints.familyName],
            textInputAction: TextInputAction.next,
            onChanged: (_) {
              if (_familyNameError != null) {
                setState(() => _familyNameError = null);
              }
            },
          ),
          if (_familyNameError != null) VFieldError(_familyNameError!),
        ],
      ),
    );

    final givenField = VField(
      invalid: _givenNameError != null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const VFieldLabel('Tên', isRequired: true),
          VTextField(
            key: const Key('invitation_register_given_name'),
            controller: _givenNameController,
            hintText: 'Nhập tên',
            enabled: !isSubmitting,
            autofillHints: const [AutofillHints.givenName],
            textInputAction: TextInputAction.next,
            onChanged: (_) {
              if (_givenNameError != null) {
                setState(() => _givenNameError = null);
              }
            },
          ),
          if (_givenNameError != null) VFieldError(_givenNameError!),
        ],
      ),
    );

    final emailField = VField(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const VFieldLabel('Email'),
          VEmailField(
            key: const Key('invitation_locked_email'),
            controller: _emailController,
            enabled: false,
            autofillHints: const [AutofillHints.email],
          ),
        ],
      ),
    );

    final phoneField = VField(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const VFieldLabel('Số điện thoại'),
          VPhoneField(
            key: const Key('invitation_register_phone'),
            controller: _phoneController,
            hintText: 'Nhập số điện thoại',
            validateOnChanged: false,
            enabled: !isSubmitting,
            autofillHints: const [AutofillHints.telephoneNumber],
            textInputAction: TextInputAction.next,
            onChanged: (_) {
              if (_phoneError != null) {
                setState(() => _phoneError = null);
              }
            },
          ),
          if (_phoneError != null) VFieldError(_phoneError!),
        ],
      ),
    );

    final passwordField = VField(
      invalid: _passwordError != null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const VFieldLabel('Mật khẩu', isRequired: true),
          VPasswordField(
            key: const Key('invitation_register_password'),
            controller: _passwordController,
            hintText: 'Nhập mật khẩu',
            minLength: PasswordPolicy.minLength,
            validateOnChanged: false,
            enabled: !isSubmitting,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.next,
            onChanged: (_) {
              if (_passwordError != null) {
                setState(() => _passwordError = null);
              }
            },
          ),
          if (_passwordError != null)
            VFieldError(_passwordError!)
          else
            const VFieldDescription(PasswordPolicy.requirementText),
        ],
      ),
    );

    final confirmField = VField(
      invalid: _confirmPasswordError != null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const VFieldLabel('Xác nhận mật khẩu', isRequired: true),
          VPasswordField(
            key: const Key('invitation_register_confirm_password'),
            controller: _confirmPasswordController,
            hintText: 'Nhập lại mật khẩu',
            minLength: 1,
            validateOnChanged: false,
            enabled: !isSubmitting,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.done,
            onChanged: (_) {
              if (_confirmPasswordError != null) {
                setState(() => _confirmPasswordError = null);
              }
            },
            onSubmitted: (_) => _submit(),
          ),
          if (_confirmPasswordError != null) VFieldError(_confirmPasswordError!),
        ],
      ),
    );

    return wide
        ? InvitationRegisterWide(
            tenantName: inspection.tenantName,
            email: inspection.inviteeEmail,
            familyField: familyField,
            givenField: givenField,
            emailField: emailField,
            phoneField: phoneField,
            passwordField: passwordField,
            confirmField: confirmField,
            isSubmitting: isSubmitting,
            onSubmit: _submit,
            onBack: widget.onBack,
          )
        : InvitationRegisterNarrow(
            tenantName: inspection.tenantName,
            email: inspection.inviteeEmail,
            familyField: familyField,
            givenField: givenField,
            emailField: emailField,
            phoneField: phoneField,
            passwordField: passwordField,
            confirmField: confirmField,
            isSubmitting: isSubmitting,
            onSubmit: _submit,
            onBack: widget.onBack,
          );
  }
}
