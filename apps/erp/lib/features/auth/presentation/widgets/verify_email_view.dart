import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_design_system/design_system.dart';

import '../../../../core/session/session_controller.dart';
import '../../../iam/data/models/password_reset_result.dart';
import '../../data/auth_repository.dart';
import '../../logic/verify_email_cubit.dart';
import '../../logic/verify_email_state.dart';
import 'otp_code_field.dart';
import 'resend_countdown.dart';

class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({
    super.key,
    required this.email,
    required this.auth,
    required this.session,
    this.prompt,
    this.onVerified,
    this.clock,
  });

  final String email;
  final AuthRepository auth;
  final SessionController session;
  final String? prompt;
  final VoidCallback? onVerified;
  final DateTime Function()? clock;

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  late final VerifyEmailCubit _cubit;
  late final TextEditingController _code;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController();
    _cubit = VerifyEmailCubit(
      auth: widget.auth,
      session: widget.session,
      email: widget.email,
      clock: widget.clock,
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _cubit.onTick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.vColors;
    final prompt = widget.prompt ??
        'Mã xác minh gồm 6 chữ số đã được gửi tới ${maskEmail(widget.email)}.';
    return BlocConsumer<VerifyEmailCubit, VerifyEmailState>(
      bloc: _cubit,
      listenWhen: (previous, current) => !previous.verified && current.verified,
      listener: (context, state) => widget.onVerified?.call(),
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VText(
              prompt,
              variant: VTextVariant.bodyDefault,
              color: colors.textSecondary,
            ),
            const VGap.lg(),
            OtpCodeField(
              controller: _code,
              enabled: !state.submitting,
            ),
            if (state.failure != null) ...[
              const VGap.sm(),
              VFieldError(state.failure!),
            ],
            const VGap.md(),
            ResendCountdown(
              remaining: state.remaining,
              onResend: state.canResend ? () => _cubit.resend() : null,
            ),
            const VGap.lg(),
            VButton(
              key: const Key('signup_verify'),
              label: 'Xác minh',
              isLoading: state.submitting,
              fullWidth: true,
              onPressed: state.submitting ? null : () => _cubit.verify(_code.text),
            ),
          ],
        );
      },
    );
  }
}
