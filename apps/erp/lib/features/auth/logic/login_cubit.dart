import 'package:erp/core/iam/iam_ui_failure.dart';
import 'package:erp/core/iam/iam_ui_failure_mapper.dart';
import 'package:erp/core/session/session_controller.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_iam_application/application.dart';

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
      ),
    );

    try {
      final userId = await _auth.signIn(email: email, password: password);
      _session.applySignedInUser(userId);
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
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          failure: IamUiFailureMapper.from(error),
        ),
      );
    }
  }
}
