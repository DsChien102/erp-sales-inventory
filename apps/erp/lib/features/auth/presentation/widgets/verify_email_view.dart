import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:c45_design_system/design_system.dart';

import '../../../../core/session/session_controller.dart';
import '../../../iam/data/models/password_reset_result.dart';
import '../../data/auth_repository.dart';
import '../../logic/verify_email_cubit.dart';
import '../../logic/verify_email_state.dart';
import '../../../../core/widgets/flow/resend_countdown.dart';

class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({
    super.key,
    required this.email,
    required this.auth,
    required this.session,
    this.prompt,
    this.showPrompt = true,
    this.onVerified,
    this.clock,
    this.allowImmediateResend = false,
    this.deferSignedIn = false,
    this.initialResendCooldown,
  });

  final String email;
  final AuthRepository auth;
  final SessionController session;
  final String? prompt;

  /// false: trang tự vẽ lời nhắc (ID-03 iPhone).
  final bool showPrompt;
  final void Function(String userId)? onVerified;
  final DateTime Function()? clock;
  final bool allowImmediateResend;

  /// Không gắn `signedIn` ngay sau OTP. Trang đăng ký tự gắn sau khi ghi mật khẩu.
  final bool deferSignedIn;

  /// Đếm ngược ban đầu khi đăng ký lại còn trong cửa sổ gửi mã.
  final Duration? initialResendCooldown;

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  late final VerifyEmailCubit _cubit;
  String _code = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _cubit = VerifyEmailCubit(
      auth: widget.auth,
      session: widget.session,
      email: widget.email,
      clock: widget.clock,
      allowImmediateResend: widget.allowImmediateResend,
      deferSignedIn: widget.deferSignedIn,
      initialCooldown: widget.initialResendCooldown,
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _cubit.onTick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final prompt =
        widget.prompt ??
        'Mã xác minh gồm 6 chữ số đã được gửi tới ${maskEmail(widget.email)}.';
    return BlocConsumer<VerifyEmailCubit, VerifyEmailState>(
      bloc: _cubit,
      listenWhen: (previous, current) =>
          (!previous.verified && current.verified) ||
          (previous.resendFailure != current.resendFailure &&
              current.resendFailure != null),
      listener: (context, state) {
        if (state.verified) {
          widget.onVerified?.call(state.verifiedUserId ?? '');
        }
        final resendFailure = state.resendFailure;
        if (resendFailure != null) {
          VToast.show(
            context,
            title: 'Không gửi được mã',
            message: resendFailure,
            type: VToastType.danger,
          );
        }
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showPrompt) ...[
              VText(
                prompt,
                variant: VTextVariant.bodyDefault,
                color: colors.textSecondary,
              ),
              const VGap.lg(),
            ],
            VField(
              invalid: state.failure != null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const VFieldLabel('Mã xác minh', isRequired: true),
                  KeyedSubtree(
                    key: const Key('otp_code_field'),
                    child: VVerificationCodeField(
                      length: 6,
                      layout: VVerificationCodeLayout.fill,
                      charset: VVerificationCodeCharset.numeric,
                      autofocus: true,
                      enabled: !state.submitting,
                      semanticLabel: 'Mã xác minh 6 chữ số',
                      onChanged: (value) => _code = value,
                      onCompleted: (value) => _cubit.verify(value),
                    ),
                  ),
                  if (state.failure != null) VFieldError(state.failure!),
                ],
              ),
            ),
            const VGap.lg(),
            VButton(
              key: const Key('signup_verify'),
              label: 'Xác minh',
              isLoading: state.submitting,
              fullWidth: true,
              onPressed: state.submitting ? null : () => _cubit.verify(_code),
            ),
            ResendCountdown(
              remaining: state.remaining,
              onResend: state.canResend ? () => _cubit.resend() : null,
            ),
          ],
        );
      },
    );
  }
}
