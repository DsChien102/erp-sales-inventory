import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/iam/iam_ui_failure_mapper.dart';
import 'package:erp/core/session/session_controller.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/auth_repository.dart';
import 'verify_email_state.dart';

final class VerifyEmailCubit extends Cubit<VerifyEmailState> {
  VerifyEmailCubit({
    required AuthRepository auth,
    required SessionController session,
    required this.email,
    DateTime Function()? clock,
    Duration cooldown = const Duration(seconds: 60),
    Duration? initialCooldown,
    bool allowImmediateResend = false,
    this.deferSignedIn = false,
  }) : _auth = auth,
       _session = session,
       _clock = clock ?? DateTime.now,
       _cooldown = cooldown,
       super(
         _initial(
           clock: clock ?? DateTime.now,
           cooldown: cooldown,
           initialCooldown: initialCooldown,
           allowImmediateResend: allowImmediateResend,
         ),
       );

  final AuthRepository _auth;
  final SessionController _session;
  final DateTime Function() _clock;
  final Duration _cooldown;
  final String email;
  final bool deferSignedIn;

  static VerifyEmailState _initial({
    required DateTime Function() clock,
    required Duration cooldown,
    required Duration? initialCooldown,
    required bool allowImmediateResend,
  }) {
    final now = clock();
    return VerifyEmailState(
      now: now,
      resendAvailableAt: allowImmediateResend ? now : now.add(initialCooldown ?? cooldown),
    );
  }

  void onTick() {
    if (isClosed) return;
    emit(state.copyWith(now: _clock()));
  }

  Future<void> verify(String code) async {
    if (isClosed || state.submitting || state.verified) return;
    final trimmed = code.trim();
    if (trimmed.length != 6) {
      emit(state.copyWith(failure: 'Mã xác minh không đúng hoặc đã hết hạn.'));
      return;
    }
    emit(
      state.copyWith(
        submitting: true,
        clearFailure: true,
        clearResendFailure: true,
      ),
    );
    if (deferSignedIn) _session.holdSignedInApply();
    try {
      final userId = await _auth.verifySignupOtp(email: email, code: trimmed);
      if (isClosed) {
        if (deferSignedIn) _session.applySignedInUser(userId);
        return;
      }
      if (!deferSignedIn) _session.applySignedInUser(userId);
      emit(
        state.copyWith(
          submitting: false,
          verified: true,
          verifiedUserId: userId,
          clearFailure: true,
        ),
      );
    } catch (error) {
      if (deferSignedIn) _session.releaseSignedInHold();
      if (isClosed) return;
      emit(
        state.copyWith(
          submitting: false,
          failure: IamUiFailureMapper.from(error).message,
        ),
      );
    }
  }

  Future<void> resend() async {
    if (isClosed || !state.canResend) return;
    emit(
      state.copyWith(
        resending: true,
        clearFailure: true,
        clearResendFailure: true,
        now: _clock(),
      ),
    );
    try {
      await _auth.resendSignupOtp(email);
      if (isClosed) return;
      final now = _clock();
      emit(
        state.copyWith(
          resending: false,
          now: now,
          resendAvailableAt: now.add(_cooldown),
        ),
      );
    } catch (error) {
      if (isClosed) return;
      if (error is AppException && error.code == AppErrorCode.resendCooldown) {
        final now = _clock();
        emit(
          state.copyWith(
            resending: false,
            now: now,
            resendAvailableAt: now.add(Duration(seconds: _cooldownSeconds(error))),
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          resending: false,
          now: _clock(),
          // Mã đã đúng trong lúc chờ: lỗi gửi lại không còn ý nghĩa.
          resendFailure: state.verified
              ? null
              : IamUiFailureMapper.from(error).message,
        ),
      );
    }
  }

  static int _cooldownSeconds(AppException error) {
    final raw = error.details?['seconds'];
    if (raw is int && raw > 0) return raw;
    return 60;
  }
}
