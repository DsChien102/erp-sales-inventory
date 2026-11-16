import 'package:erp/core/iam/iam_ui_failure.dart';
import 'package:erp/core/iam/iam_ui_failure_mapper.dart';
import 'package:erp/core/session/session_controller.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erp/core/iam/iam_codes.dart';

import '../data/auth_repository.dart';
import 'login_state.dart';

final class LoginCubit extends Cubit<LoginState> {
  LoginCubit({
    required AuthRepository auth,
    required SessionController session,
  }) : _auth = auth,
       _session = session,
       super(const LoginState());

  final AuthRepository _auth;
  final SessionController _session;

  Future<void> submit({
    required String email,
    required String password,
  }) async {
    if (state.isSubmitting) {
      return;
    }

    emit(
      state.copyWith(
        status: LoginStatus.submitting,
        clearFailure: true,
        clearSession: true,
        clearVerificationEmail: true,
      ),
    );

    try {
      final userId = await _auth.signIn(email: email, password: password);
      _session.applySignedInUser(userId);
      // Router có thể đã rời /login khi phiên được gắn và đóng cubit giữa lúc await.
      if (isClosed) {
        return;
      }
      final session = _session.readSession();

      if (!session.isAuthenticated) {
        emit(
          state.copyWith(
            status: LoginStatus.failure,
            session: session,
            failure: const IamUiFailure(
              code: IamBlockedCodes.authenticationRequired,
              message: 'Phiên đăng nhập không hợp lệ.',
            ),
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: LoginStatus.success,
          session: session,
          clearFailure: true,
        ),
      );
    } catch (error) {
      if (isClosed) {
        return;
      }
      final failure = IamUiFailureMapper.from(error);
      if (failure.code == IamBlockedCodes.identityEmailNotVerified) {
        emit(
          state.copyWith(
            status: LoginStatus.needsVerification,
            failure: failure,
            verificationEmail: email.trim(),
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          failure: failure,
        ),
      );
    }
  }
}
