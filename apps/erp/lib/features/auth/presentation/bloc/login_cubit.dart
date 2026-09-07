import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:erp/features/iam/presentation.dart';

import 'login_state.dart';

final class LoginCubit extends Cubit<LoginState> {
  LoginCubit({required IIamModule iamModule}) : _iamModule = iamModule, super(const LoginState());

  final IIamModule _iamModule;

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
      await _iamModule.executeCommandAsync(
        SignInTenantUserCommand(email: email, password: password),
      );
      final session = await _iamModule.executeQueryAsync<SessionDto>(
        GetCurrentSessionQuery(),
      );

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
