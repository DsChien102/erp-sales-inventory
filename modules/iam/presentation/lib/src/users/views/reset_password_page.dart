import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import '../widgets/reset_password_create_password_step.dart';
import '../widgets/reset_password_verify_code_step.dart';

enum ResetPasswordStep { verifyCode, createNewPassword }

/// Trang Đặt lại mật khẩu (TA-D-03).
class ResetPasswordPage extends StatefulWidget {
  final String emailMasked;
  final IIamModule? iamModule;

  const ResetPasswordPage({
    super.key,
    this.emailMasked = 'mi***@gmail.com',
    this.iamModule,
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
  bool _isRequesting = false;
  String? _newPasswordError;
  String? _confirmPasswordError;
  String? _operationId;
  late String _emailMasked;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _emailMasked = widget.emailMasked;
    _startResendTimer();
    if (widget.iamModule != null) {
      _requestReset();
    }
  }

  Future<void> _requestReset() async {
    final module = widget.iamModule;
    if (module == null || _isRequesting) return;
    setState(() => _isRequesting = true);
    try {
      final op = await module.executeCommandAsync<PasswordResetOperationDto>(
        RequestMyPasswordResetCommand(),
      );
      if (!mounted) return;
      setState(() {
        _operationId = op.operationId;
        _emailMasked = op.maskedEmail;
        _isRequesting = false;
        _secondsRemaining = op.resendAfterSeconds ?? 45;
      });
      _startResendTimer();
    } on ApplicationException catch (e) {
      if (!mounted) return;
      setState(() => _isRequesting = false);
      VToast.show(
        context,
        title: 'Không gửi được mã',
        message: e.message,
        type: VToastType.danger,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRequesting = false);
      VToast.show(
        context,
        title: 'Không gửi được mã',
        message: e.toString(),
        type: VToastType.danger,
      );
    }
  }

void _startResendTimer() {
    _resendTimer?.cancel();
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

  Future<void> _handleResendCode() async {
    final module = widget.iamModule;
    if (module != null && _operationId != null) {
      try {
        final op = await module.executeCommandAsync<PasswordResetOperationDto>(
          ResendMyPasswordResetCommand(operationId: _operationId!),
        );
        if (!mounted) return;
        setState(() {
          _operationId = op.operationId;
          _emailMasked = op.maskedEmail;
          _secondsRemaining = op.resendAfterSeconds ?? 45;
        });
        _startResendTimer();
        VToast.show(
          context,
          title: 'Thông báo',
          message: 'Đã gửi lại mã xác nhận.',
          type: VToastType.info,
        );
      } on ApplicationException catch (e) {
        if (!mounted) return;
        VToast.show(
          context,
          title: 'Không gửi lại được',
          message: e.message,
          type: VToastType.danger,
        );
      }
      return;
    }

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

    final module = widget.iamModule;
    if (module != null) {
      try {
        await module.executeCommandAsync<void>(
          VerifyMyPasswordResetCommand(
            operationId: _operationId ?? '',
            code: _codeController.text.trim(),
          ),
        );
        if (!mounted) return;
        setState(() {
          _isVerifyingCode = false;
          _currentStep = ResetPasswordStep.createNewPassword;
        });
      } on ApplicationException catch (e) {
        if (!mounted) return;
        setState(() => _isVerifyingCode = false);
        VToast.show(
          context,
          title: 'Mã không hợp lệ',
          message: e.message,
          type: VToastType.danger,
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _isVerifyingCode = false);
        VToast.show(
          context,
          title: 'Mã không hợp lệ',
          message: e.toString(),
          type: VToastType.danger,
        );
      }
      return;
    }

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

    final module = widget.iamModule;
    if (module != null) {
      try {
        await module.executeCommandAsync<void>(
          CompleteMyPasswordResetCommand(
            operationId: _operationId ?? '',
            newPassword: newPass,
          ),
        );
        if (!mounted) return;
        Navigator.of(context).pop(true);
      } on ApplicationException catch (e) {
        if (!mounted) return;
        setState(() => _isSubmittingPassword = false);
        VToast.show(
          context,
          title: 'Không thể đặt lại mật khẩu',
          message: e.message,
          type: VToastType.danger,
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _isSubmittingPassword = false);
        VToast.show(
          context,
          title: 'Không thể đặt lại mật khẩu',
          message: e.toString(),
          type: VToastType.danger,
        );
      }
      return;
    }

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
    final isLoading =
        _isVerifyingCode || _isSubmittingPassword || _isRequesting;

    return Stack(
      children: [
        VPageScaffold(
          title: 'Đặt lại mật khẩu',
          body: _currentStep == ResetPasswordStep.verifyCode
              ? ResetPasswordVerifyCodeStep(
                  emailMasked: _emailMasked,
                  codeController: _codeController,
                  secondsRemaining: _secondsRemaining,
                  isVerifying: _isVerifyingCode,
                  onCodeChanged: (_) => setState(() {}),
                  onVerify: _handleVerifyCode,
                  onResend: _handleResendCode,
                )
              : ResetPasswordCreatePasswordStep(
                  newPasswordController: _newPasswordController,
                  confirmPasswordController: _confirmPasswordController,
                  newPasswordError: _newPasswordError,
                  confirmPasswordError: _confirmPasswordError,
                  onChanged: () {
                    setState(() {
                      _newPasswordError = null;
                      _confirmPasswordError = null;
                    });
                  },
                ),
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
}
