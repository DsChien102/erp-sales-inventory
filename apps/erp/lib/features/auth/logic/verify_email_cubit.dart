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
  }) : _auth = auth,
       _session = session,
       _clock = clock ?? DateTime.now,
       _cooldown = cooldown,
       super(
         VerifyEmailState(
           now: (clock ?? DateTime.now)(),
           resendAvailableAt: (clock ?? DateTime.now)().add(cooldown),
         ),
       );

  final AuthRepository _auth;
  final SessionController _session;
  final DateTime Function() _clock;
  final Duration _cooldown;
  final String email;

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
    emit(state.copyWith(submitting: true, clearFailure: true));
    try {
      final userId = await _auth.verifySignupOtp(email: email, code: trimmed);
      _session.applySignedInUser(userId);
      if (isClosed) return;
      emit(state.copyWith(submitting: false, verified: true, clearFailure: true));
    } catch (error) {
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
    emit(state.copyWith(submitting: true, clearFailure: true, now: _clock()));
    try {
      await _auth.resendSignupOtp(email);
      if (isClosed) return;
      final now = _clock();
      emit(
        state.copyWith(
          submitting: false,
          now: now,
          resendAvailableAt: now.add(_cooldown),
          clearFailure: true,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          submitting: false,
          now: _clock(),
          failure: IamUiFailureMapper.from(error).message,
        ),
      );
    }
  }
}
