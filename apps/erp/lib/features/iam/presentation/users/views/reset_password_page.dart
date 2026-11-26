import 'dart:async';

import 'package:c45_design_system/design_system.dart';
import 'package:erp/core/config/wide_layout.dart';
import 'package:erp/core/validation/password_policy.dart';
import 'package:erp/features/auth/data/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../logic/password_reset_cubit.dart';
import '../../../logic/password_reset_state.dart';
import '../../shared/iam_ui_failure.dart';
import '../widgets/reset_password_narrow.dart';
import '../widgets/reset_password_wide.dart';

/// Trang Đặt lại mật khẩu (TA-D-03).
class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({
    super.key,
    this.emailMasked = '',
    this.requestEmail,
    this.authRepository,
    this.cubit,
    this.clock,
  });

  final String emailMasked;

  /// Logged-out forgot-password: request a code for this email (public commands).
  final String? requestEmail;
  final AuthRepository? authRepository;
  final PasswordResetCubit? cubit;
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: const _ResetPasswordBody(),
      );
    }
    if (authRepository != null) {
      return BlocProvider(
        create: (_) {
          final created = PasswordResetCubit(
            authRepository: authRepository!,
            requestEmail: requestEmail,
            clock: clock,
          );
          unawaited(created.request());
          return created;
        },
        child: const _ResetPasswordBody(),
      );
    }
    return _ResetPasswordSampleBody(emailMasked: emailMasked);
  }
}

Widget _buildResetCodeField({
  required Key fieldKey,
  required bool isVerifying,
  required String? codeError,
  required ValueChanged<String> onChanged,
  required VoidCallback onCompleted,
}) {
  return VField(
    invalid: codeError != null,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const VFieldLabel('Mã xác nhận', isRequired: true),
        VVerificationCodeField(
          key: fieldKey,
          length: 6,
          charset: VVerificationCodeCharset.numeric,
          layout: VVerificationCodeLayout.fill,
          autofocus: true,
          enabled: !isVerifying,
          onChanged: onChanged,
          onCompleted: (_) => onCompleted(),
        ),
        if (codeError != null) VFieldError(codeError),
      ],
    ),
  );
}

Widget _buildPasswordField({
  required String label,
  required TextEditingController controller,
  required String? error,
  required VoidCallback onChanged,
}) {
  return VField(
    invalid: error != null,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VFieldLabel(label, isRequired: true),
        VPasswordField(
          hintText: '••••••••••••',
          controller: controller,
          onChanged: (_) => onChanged(),
        ),
        if (error != null) VFieldError(error),
      ],
    ),
  );
}

class _ResetPasswordSampleBody extends StatefulWidget {
  const _ResetPasswordSampleBody({required this.emailMasked});

  final String emailMasked;

  @override
  State<_ResetPasswordSampleBody> createState() =>
      _ResetPasswordSampleBodyState();
}

class _ResetPasswordSampleBodyState extends State<_ResetPasswordSampleBody> {
  PasswordResetStep _currentStep = PasswordResetStep.verifyCode;

  final _codeFieldKey = GlobalKey();
  String _code = '';
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;

  static const _resendCooldownSeconds = 60;

  Timer? _resendTimer;
  int _secondsRemaining = _resendCooldownSeconds;

  bool _isVerifyingCode = false;
  bool _isSubmittingPassword = false;
  String? _newPasswordError;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _startResendTimer();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _secondsRemaining = _resendCooldownSeconds;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handleResendCode() async {
    _startResendTimer();
    VToast.show(
      context,
      title: 'Thông báo',
      message: 'Đã gửi lại mã xác nhận.',
      type: VToastType.info,
    );
  }

  Future<void> _handleVerifyCode() async {
    if (!RegExp(r'^\d{6}$').hasMatch(_code) || _isVerifyingCode) return;
    setState(() => _isVerifyingCode = true);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _isVerifyingCode = false;
      _currentStep = PasswordResetStep.createNewPassword;
    });
  }

  Future<void> _handleResetPassword() async {
    if (!_isPasswordFormFilled || _isSubmittingPassword) return;

    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    String? newErr;
    String? confirmErr;

    final policyError = PasswordPolicy.validate(newPass);
    if (policyError != null) {
      newErr = policyError;
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

    setState(() => _isSubmittingPassword = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _isPasswordFormFilled =>
      _newPasswordController.text.isNotEmpty &&
      _confirmPasswordController.text.isNotEmpty;

  void _clearPasswordErrors() {
    setState(() {
      _newPasswordError = null;
      _confirmPasswordError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final wide = isWideLayout(context);
    final isLoading = _isVerifyingCode || _isSubmittingPassword;
    final canSubmitCode = RegExp(r'^\d{6}$').hasMatch(_code) && !_isVerifyingCode;
    final remaining = Duration(seconds: _secondsRemaining);
    final onResend = _secondsRemaining == 0 ? _handleResendCode : null;

    final Widget body;
    if (_currentStep == PasswordResetStep.verifyCode) {
      final codeField = _buildResetCodeField(
        fieldKey: _codeFieldKey,
        isVerifying: _isVerifyingCode,
        codeError: null,
        onChanged: (value) => setState(() => _code = value),
        onCompleted: _handleVerifyCode,
      );
      body = wide
          ? ResetVerifyWide(
              maskedEmail: widget.emailMasked,
              codeField: codeField,
              canSubmit: canSubmitCode,
              remaining: remaining,
              onVerify: _handleVerifyCode,
              onResend: onResend,
            )
          : ResetVerifyNarrow(
              maskedEmail: widget.emailMasked,
              codeField: codeField,
              canSubmit: canSubmitCode,
              remaining: remaining,
              onVerify: _handleVerifyCode,
              onResend: onResend,
            );
    } else {
      final newPwField = _buildPasswordField(
        label: 'Mật khẩu mới',
        controller: _newPasswordController,
        error: _newPasswordError,
        onChanged: _clearPasswordErrors,
      );
      final confirmPwField = _buildPasswordField(
        label: 'Nhập lại mật khẩu mới',
        controller: _confirmPasswordController,
        error: _confirmPasswordError,
        onChanged: _clearPasswordErrors,
      );
      body = wide
          ? ResetCreateWide(
              newPasswordField: newPwField,
              confirmPasswordField: confirmPwField,
            )
          : ResetCreateNarrow(
              newPasswordField: newPwField,
              confirmPasswordField: confirmPwField,
            );
    }

    return Stack(
      children: [
        Scaffold(
          backgroundColor: wide ? colors.background : colors.surface,
          appBar: const VAppBar(title: 'Đặt lại mật khẩu'),
          body: body,
          bottomNavigationBar:
              _currentStep == PasswordResetStep.createNewPassword
                  ? _PasswordBottomBar(
                      wide: wide,
                      isLoading: isLoading,
                      onBack: () {
                        setState(() {
                          _code = '';
                          _currentStep = PasswordResetStep.verifyCode;
                        });
                      },
                      onSubmit: _isPasswordFormFilled && !isLoading
                          ? _handleResetPassword
                          : null,
                    )
                  : null,
        ),
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: colors.surface.withValues(alpha: 0.5),
              child: const Center(child: VLoading(size: 40)),
            ),
          ),
      ],
    );
  }
}

class _ResetPasswordBody extends StatefulWidget {
  const _ResetPasswordBody();

  @override
  State<_ResetPasswordBody> createState() => _ResetPasswordBodyState();
}

class _ResetPasswordBodyState extends State<_ResetPasswordBody> {
  final _codeFieldKey = GlobalKey();
  String _code = '';
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;
  Timer? _tickTimer;
  String? _newPasswordError;
  String? _confirmPasswordError;
  IamUiFailure? _lastShownFailure;
  bool _completionHandled = false;

  @override
  void initState() {
    super.initState();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      context.read<PasswordResetCubit>().tick();
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _isPasswordFormFilled =>
      _newPasswordController.text.isNotEmpty &&
      _confirmPasswordController.text.isNotEmpty;

  Future<void> _handleVerify() async {
    await context.read<PasswordResetCubit>().verify(_code);
  }

  Future<void> _handleResend() async {
    final cubit = context.read<PasswordResetCubit>();
    await cubit.resend();
    if (!mounted) return;
    if (cubit.state.failure == null) {
      VToast.show(
        context,
        title: 'Thông báo',
        message: 'Đã gửi lại mã xác nhận.',
        type: VToastType.info,
      );
    }
  }

  Future<void> _handleComplete() async {
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    String? newErr;
    String? confirmErr;

    final policyError = PasswordPolicy.validate(newPass);
    if (policyError != null) {
      newErr = policyError;
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

    await context.read<PasswordResetCubit>().complete(newPass);
  }

  void _clearPasswordErrors() {
    setState(() {
      _newPasswordError = null;
      _confirmPasswordError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final wide = isWideLayout(context);
    final pageBg = wide ? colors.background : colors.surface;

    return BlocConsumer<PasswordResetCubit, PasswordResetState>(
      listener: (context, state) {
        final isInitialRequestFailure =
            state.step == PasswordResetStep.initial && state.request == null;
        if (state.failure != null &&
            !isInitialRequestFailure &&
            !identical(state.failure, _lastShownFailure)) {
          _lastShownFailure = state.failure;
          VToast.show(
            context,
            title: 'Không thể tiếp tục',
            message: state.failure!.message,
            type: VToastType.danger,
          );
        }

        if (state.completion != null && !_completionHandled) {
          _completionHandled = true;
          Navigator.of(context).pop(true);
        }
      },
      builder: (context, state) {
        if (state.step == PasswordResetStep.initial && state.isSubmitting) {
          return Scaffold(
            backgroundColor: pageBg,
            appBar: const VAppBar(title: 'Đặt lại mật khẩu'),
            body: const Center(child: VLoading(size: 40)),
          );
        }

        if (state.step == PasswordResetStep.initial &&
            state.failure != null &&
            state.request == null) {
          return Scaffold(
            backgroundColor: pageBg,
            appBar: const VAppBar(title: 'Đặt lại mật khẩu'),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.all(VSpacing.screenMobile),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        header: true,
                        child: VText(
                          'Không gửi được mã',
                          variant: VTextVariant.headingH4,
                        ),
                      ),
                      const VGap.sm(),
                      VText(
                        state.failure!.message,
                        variant: VTextVariant.bodySmall,
                        color: colors.textSecondary,
                        textAlign: TextAlign.center,
                      ),
                      const VGap.lg(),
                      VButton(
                        label: 'Thử lại',
                        onPressed: state.isSubmitting
                            ? null
                            : () => context.read<PasswordResetCubit>().retry(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final isLoading = state.isSubmitting;
        final isVerifying =
            state.isSubmitting && state.step == PasswordResetStep.verifyCode;
        final canSubmitCode =
            RegExp(r'^\d{6}$').hasMatch(_code) && !isVerifying;
        final maskedEmail = state.maskedEmail.isEmpty
            ? '***'
            : state.maskedEmail;
        final remaining = Duration(seconds: state.resendSecondsRemaining);
        final onResend = state.canResend ? _handleResend : null;

        final Widget body;
        if (state.step == PasswordResetStep.createNewPassword) {
          final newPwField = _buildPasswordField(
            label: 'Mật khẩu mới',
            controller: _newPasswordController,
            error: _newPasswordError,
            onChanged: _clearPasswordErrors,
          );
          final confirmPwField = _buildPasswordField(
            label: 'Nhập lại mật khẩu mới',
            controller: _confirmPasswordController,
            error: _confirmPasswordError,
            onChanged: _clearPasswordErrors,
          );
          body = wide
              ? ResetCreateWide(
                  newPasswordField: newPwField,
                  confirmPasswordField: confirmPwField,
                )
              : ResetCreateNarrow(
                  newPasswordField: newPwField,
                  confirmPasswordField: confirmPwField,
                );
        } else {
          final codeField = _buildResetCodeField(
            fieldKey: _codeFieldKey,
            isVerifying: isVerifying,
            codeError: state.codeError,
            onChanged: (value) {
              setState(() => _code = value);
              context.read<PasswordResetCubit>().clearCodeError();
            },
            onCompleted: _handleVerify,
          );
          body = wide
              ? ResetVerifyWide(
                  maskedEmail: maskedEmail,
                  codeField: codeField,
                  canSubmit: canSubmitCode,
                  remaining: remaining,
                  onVerify: _handleVerify,
                  onResend: onResend,
                )
              : ResetVerifyNarrow(
                  maskedEmail: maskedEmail,
                  codeField: codeField,
                  canSubmit: canSubmitCode,
                  remaining: remaining,
                  onVerify: _handleVerify,
                  onResend: onResend,
                );
        }

        return Stack(
          children: [
            Scaffold(
              backgroundColor: pageBg,
              appBar: const VAppBar(title: 'Đặt lại mật khẩu'),
              body: body,
              bottomNavigationBar:
                  state.step == PasswordResetStep.createNewPassword
                      ? _PasswordBottomBar(
                          wide: wide,
                          isLoading: isLoading,
                          onBack: () {
                            setState(() => _code = '');
                            context.read<PasswordResetCubit>().returnToVerify();
                          },
                          onSubmit: _isPasswordFormFilled && !isLoading
                              ? _handleComplete
                              : null,
                        )
                      : null,
            ),
            if (isLoading)
              Positioned.fill(
                child: Container(
                  color: colors.surface.withValues(alpha: 0.5),
                  child: const Center(child: VLoading(size: 40)),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PasswordBottomBar extends StatelessWidget {
  const _PasswordBottomBar({
    required this.wide,
    required this.isLoading,
    required this.onBack,
    required this.onSubmit,
  });

  final bool wide;
  final bool isLoading;
  final VoidCallback onBack;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.borderDefault),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: wide ? 520 : 480,
            ),
            child: Padding(
              padding: const EdgeInsets.all(VSpacing.screenMobile),
              child: Row(
                children: [
                  Expanded(
                    child: VButton(
                      label: 'Quay lại',
                      variant: VButtonVariant.secondary,
                      fullWidth: true,
                      onPressed: isLoading ? null : onBack,
                    ),
                  ),
                  const VGap.horizontalSm(),
                  Expanded(
                    child: VButton(
                      label: 'Đặt lại mật khẩu',
                      variant: VButtonVariant.primary,
                      tone: VComponentTone.primary,
                      fullWidth: true,
                      onPressed: onSubmit,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
