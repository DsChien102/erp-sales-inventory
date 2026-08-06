import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';

import '../../shared/iam_ui_failure.dart';
import '../bloc/password_reset_cubit.dart';
import '../bloc/password_reset_state.dart';
import '../widgets/reset_password_create_password_step.dart';
import '../widgets/reset_password_verify_code_step.dart';

/// Trang Đặt lại mật khẩu (TA-D-03).
class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({
    super.key,
    this.emailMasked = '',
    this.iamModule,
    this.cubit,
    this.clock,
  });

  final String emailMasked;
  final IIamModule? iamModule;
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
    if (iamModule != null) {
      return BlocProvider(
        create: (_) {
          final created = PasswordResetCubit(
            iamModule: iamModule!,
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

class _ResetPasswordSampleBody extends StatefulWidget {
  const _ResetPasswordSampleBody({required this.emailMasked});

  final String emailMasked;

  @override
  State<_ResetPasswordSampleBody> createState() =>
      _ResetPasswordSampleBodyState();
}

class _ResetPasswordSampleBodyState extends State<_ResetPasswordSampleBody> {
  PasswordResetStep _currentStep = PasswordResetStep.verifyCode;

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
    _secondsRemaining = 45;
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
    if (_codeController.text.trim().isEmpty || _isVerifyingCode) return;
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
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _isPasswordFormFilled =>
      _newPasswordController.text.isNotEmpty &&
      _confirmPasswordController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final isLoading = _isVerifyingCode || _isSubmittingPassword;

    return Stack(
      children: [
        VPageScaffold(
          title: 'Đặt lại mật khẩu',
          body: _currentStep == PasswordResetStep.verifyCode
              ? ResetPasswordVerifyCodeStep(
                  emailMasked: widget.emailMasked,
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
          bottomBar: _currentStep == PasswordResetStep.createNewPassword
              ? _PasswordBottomBar(
                  isLoading: isLoading,
                  onBack: () {
                    setState(() {
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
  late final TextEditingController _codeController;
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
    _codeController = TextEditingController();
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
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _isPasswordFormFilled =>
      _newPasswordController.text.isNotEmpty &&
      _confirmPasswordController.text.isNotEmpty;

  Future<void> _handleVerify() async {
    await context.read<PasswordResetCubit>().verify(_codeController.text);
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

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;

    return BlocConsumer<PasswordResetCubit, PasswordResetState>(
      listener: (context, state) {
        if (state.failure != null &&
            !identical(state.failure, _lastShownFailure)) {
          _lastShownFailure = state.failure;
          final isRequestPhase = state.request == null;
          VToast.show(
            context,
            title: isRequestPhase ? 'Không gửi được mã' : 'Không thể tiếp tục',
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
          return const VPageScaffold(
            title: 'Đặt lại mật khẩu',
            body: Center(child: VLoading(size: 40)),
          );
        }

        if (state.step == PasswordResetStep.initial &&
            state.failure != null &&
            state.request == null) {
          return VPageScaffold(
            title: 'Đặt lại mật khẩu',
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(VSpacing.screenMobile),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VText(
                      'Không gửi được mã',
                      variant: VTextVariant.headingH4,
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
          );
        }

        final isLoading = state.isSubmitting;

        return Stack(
          children: [
            VPageScaffold(
              title: 'Đặt lại mật khẩu',
              body: state.step == PasswordResetStep.createNewPassword
                  ? ResetPasswordCreatePasswordStep(
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
                    )
                  : ResetPasswordVerifyCodeStep(
                      emailMasked: state.maskedEmail.isEmpty
                          ? '***'
                          : state.maskedEmail,
                      codeController: _codeController,
                      secondsRemaining: state.resendSecondsRemaining,
                      isVerifying: state.isSubmitting &&
                          state.step == PasswordResetStep.verifyCode,
                      onCodeChanged: (_) => setState(() {}),
                      onVerify: _handleVerify,
                      onResend: state.canResend ? _handleResend : null,
                    ),
              bottomBar: state.step == PasswordResetStep.createNewPassword
                  ? _PasswordBottomBar(
                      isLoading: isLoading,
                      onBack: () =>
                          context.read<PasswordResetCubit>().returnToVerify(),
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
    required this.isLoading,
    required this.onBack,
    required this.onSubmit,
  });

  final bool isLoading;
  final VoidCallback onBack;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    return Container(
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
    );
  }
}
