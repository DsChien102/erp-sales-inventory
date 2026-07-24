import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';

enum ResetPasswordStep { verifyCode, createNewPassword }

/// Trang Đặt lại mật khẩu (TA-D-03).
class ResetPasswordPage extends StatefulWidget {
  final String emailMasked;

  const ResetPasswordPage({
    super.key,
    this.emailMasked = 'mi***@gmail.com',
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  ResetPasswordStep _currentStep = ResetPasswordStep.verifyCode;

  late final TextEditingController _codeController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;

  Timer? _resendTimer;
  int _secondsRemaining = 45;

  bool _isVerifyingCode = false;
  bool _isSubmittingPassword = false;
  String? _newPasswordError;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _startResendTimer();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() {
      _secondsRemaining = 45;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _handleResendCode() {
    _startResendTimer();
    VToast.show(
      context,
      title: 'Thông báo',
      message: 'Đã gửi lại mã xác nhận.',
      type: VToastType.info,
    );
  }

  Future<void> _handleVerifyCode() async {
    if (!_isCodeValid || _isVerifyingCode) return;
    setState(() {
      _isVerifyingCode = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    setState(() {
      _isVerifyingCode = false;
      _currentStep = ResetPasswordStep.createNewPassword;
    });
  }

  Future<void> _handleResetPassword() async {
    if (!_isPasswordFormFilled || _isSubmittingPassword) return;

    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    String? newErr;
    String? confirmErr;

    if (newPass.length < 8) {
      newErr = 'Mật khẩu phải chứa tối thiểu 8 ký tự';
    }
    if (newPass != confirmPass) {
      confirmErr = 'Mật khẩu nhập lại không trùng khớp';
    }

    setState(() {
      _newPasswordError = newErr;
      _confirmPasswordError = confirmErr;
    });

    if (newErr != null || confirmErr != null) {
      VToast.show(
        context,
        title: 'Không thể đặt lại mật khẩu',
        message: 'Vui lòng kiểm tra lại thông tin mật khẩu bên dưới.',
        type: VToastType.danger,
      );
      return;
    }

    setState(() {
      _isSubmittingPassword = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _isCodeValid => _codeController.text.trim().isNotEmpty;

  bool get _isPasswordFormFilled =>
      _newPasswordController.text.isNotEmpty && _confirmPasswordController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isLoading = _isVerifyingCode || _isSubmittingPassword;

    return Stack(
      children: [
        VPageScaffold(
          title: 'Đặt lại mật khẩu',
          body: _currentStep == ResetPasswordStep.verifyCode
              ? _buildStep1VerifyCode(colors)
              : _buildStep2CreateNewPassword(colors),
          bottomBar: _currentStep == ResetPasswordStep.createNewPassword
              ? Container(
                  padding: const EdgeInsets.all(VSpacing.screenMobile),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border(
                      top: BorderSide(color: colors.borderDefault),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Expanded(
                          child: VButton(
                            label: 'Quay lại',
                            variant: VButtonVariant.outline,
                            fullWidth: true,
                            onPressed: isLoading
                                ? null
                                : () {
                                    setState(() {
                                      _currentStep = ResetPasswordStep.verifyCode;
                                    });
                                  },
                          ),
                        ),
                        const VGap.horizontalSm(),
                        Expanded(
                          child: VButton(
                            label: 'Đặt lại mật khẩu',
                            variant: VButtonVariant.primary,
                            tone: VComponentTone.primary,
                            fullWidth: true,
                            onPressed: _isPasswordFormFilled && !isLoading
                                ? _handleResetPassword
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
        ),
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: colors.surface.withValues(alpha: 0.5),
              child: const Center(
                child: VLoading(size: 40),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStep1VerifyCode(VColorScheme colors) {
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.screenMobile,
        vertical: VSpacing.space4,
      ),
      children: [
        // Card thông tin xác minh email
        VCard(
          padding: const EdgeInsets.all(VSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VText(
                'Xác minh email',
                variant: VTextVariant.headingH4,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const VGap.xs(),
              VText(
                'Mã 6 chữ số đã được gửi tới ${widget.emailMasked}. Xác nhận mã để tạo mật khẩu mới.',
                variant: VTextVariant.bodySmall,
                color: colors.textSecondary,
              ),
            ],
          ),
        ),
        const VGap.lg(),

        // Ô nhập mã xác nhận
        VTextField(
          label: 'Mã xác nhận',
          isRequired: true,
          hintText: '12345',
          keyboardType: TextInputType.number,
          controller: _codeController,
          onChanged: (_) => setState(() {}),
        ),
        const VGap.lg(),

        // Nút Xác nhận mã
        VButton(
          label: 'Xác nhận mã',
          variant: VButtonVariant.primary,
          tone: VComponentTone.primary,
          fullWidth: true,
          onPressed: _isCodeValid && !_isVerifyingCode ? _handleVerifyCode : null,
        ),
        const VGap.sm(),

        // Nút Gửi lại mã (Đếm ngược 45s -> Hết đếm ngược thì enable -> Bấm xong đếm ngược lại)
        VButton(
          label: _secondsRemaining > 0
              ? 'Gửi lại mã sau 00:${_secondsRemaining.toString().padLeft(2, '0')}'
              : 'Gửi lại mã',
          variant: VButtonVariant.outline,
          fullWidth: true,
          onPressed: _secondsRemaining == 0 ? _handleResendCode : null,
        ),
        const VGap.md(),

        // Dòng ghi chú chân trang
        VText(
          'Mã chỉ sử dụng một lần và hết hạn sau 10 phút.',
          variant: VTextVariant.bodySmall,
          color: colors.textSecondary,
        ),
      ],
    );
  }

  Widget _buildStep2CreateNewPassword(VColorScheme colors) {
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.screenMobile,
        vertical: VSpacing.space4,
      ),
      children: [
        VText(
          'Tạo mật khẩu mới',
          variant: VTextVariant.headingH3,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const VGap.md(),

        // Ô Mật khẩu mới
        VTextField(
          label: 'Mật khẩu mới',
          isRequired: true,
          obscureText: true,
          hintText: '••••••••••••',
          controller: _newPasswordController,
          errorText: _newPasswordError,
          onChanged: (_) {
            if (_newPasswordError != null) {
              setState(() {
                _newPasswordError = null;
              });
            } else {
              setState(() {});
            }
          },
        ),
        const VGap.md(),

        // Ô Nhập lại mật khẩu mới
        VTextField(
          label: 'Nhập lại mật khẩu mới',
          isRequired: true,
          obscureText: true,
          hintText: '••••••••••••',
          controller: _confirmPasswordController,
          errorText: _confirmPasswordError,
          onChanged: (_) {
            if (_confirmPasswordError != null) {
              setState(() {
                _confirmPasswordError = null;
              });
            } else {
              setState(() {});
            }
          },
        ),
        const VGap.lg(),

        // Card Quy tắc mật khẩu
        VCard(
          padding: const EdgeInsets.all(VSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VText(
                'Quy tắc mật khẩu',
                variant: VTextVariant.headingH4,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const VGap.xs(),
              VText(
                'Tối thiểu 8 ký tự, gồm chữ hoa, chữ thường và số.',
                variant: VTextVariant.bodySmall,
                color: colors.textSecondary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
