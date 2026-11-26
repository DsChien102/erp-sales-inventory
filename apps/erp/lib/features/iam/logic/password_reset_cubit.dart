import 'package:erp/core/validation/password_policy.dart';
import 'package:erp/features/auth/data/auth_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erp/core/iam/iam_codes.dart';

import 'iam_ui_failure.dart';
import 'iam_ui_failure_mapper.dart';
import 'password_reset_state.dart';

final class PasswordResetCubit extends Cubit<PasswordResetState> {
  PasswordResetCubit({
    required AuthRepository authRepository,
    this.requestEmail,
    DateTime Function()? clock,
  }) : _authRepository = authRepository,
       _clock = clock ?? (() => DateTime.now().toUtc()),
       super(PasswordResetState(nowUtc: (clock ?? () => DateTime.now().toUtc())()));

  final AuthRepository _authRepository;
  final DateTime Function() _clock;

  /// When set, use public (logged-out) reset-by-email commands.
  final String? requestEmail;

  bool get _isPublic => requestEmail != null && requestEmail!.trim().isNotEmpty;

  void tick() {
    if (isClosed) return;
    emit(state.copyWith(nowUtc: _clock()));
  }

  void clearCodeError() {
    if (isClosed || state.codeError == null) return;
    emit(state.copyWith(clearCodeError: true));
  }

  void returnToVerify() {
    if (isClosed) return;
    emit(
      state.copyWith(
        step: PasswordResetStep.verifyCode,
        clearCodeError: true,
      ),
    );
  }

  Future<void> request() async {
    if (isClosed || state.isSubmitting) return;
    emit(
      state.copyWith(
        isSubmitting: true,
        clearFailure: true,
        clearCodeError: true,
        nowUtc: _clock(),
      ),
    );

    try {
      final result = _isPublic
          ? await _authRepository.requestPasswordResetByEmail(requestEmail!.trim())
          : await _authRepository.requestMyPasswordReset();
      if (isClosed) return;
      emit(
        state.copyWith(
          step: PasswordResetStep.verifyCode,
          request: result,
          isSubmitting: false,
          verified: false,
          clearFailure: true,
          clearCompletion: true,
          nowUtc: _clock(),
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isSubmitting: false,
          failure: IamUiFailureMapper.from(error),
          nowUtc: _clock(),
        ),
      );
    }
  }

  /// When no operation yet, retry the initial Request (not Resend).
  Future<void> retry() async {
    if (state.request?.operationId == null) {
      await request();
      return;
    }
    await resend();
  }

  Future<void> resend() async {
    if (isClosed || state.isSubmitting) return;
    final operationId = state.request?.operationId;
    if (operationId == null || operationId.isEmpty) {
      await request();
      return;
    }

    emit(
      state.copyWith(
        isSubmitting: true,
        clearFailure: true,
        clearCodeError: true,
        nowUtc: _clock(),
      ),
    );

    try {
      final result = _isPublic
          ? await _authRepository.resendPasswordResetByEmail(operationId)
          : await _authRepository.resendMyPasswordReset(operationId);
      if (isClosed) return;
      emit(
        state.copyWith(
          request: result,
          isSubmitting: false,
          clearFailure: true,
          nowUtc: _clock(),
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isSubmitting: false,
          failure: IamUiFailureMapper.from(error),
          nowUtc: _clock(),
        ),
      );
    }
  }

  Future<void> verify(String code) async {
    if (isClosed || state.isSubmitting) return;
    final operationId = state.request?.operationId;
    if (operationId == null || operationId.isEmpty) {
      emit(
        state.copyWith(
          failure: const IamUiFailure(
            code: IamBlockedCodes.systemError,
            message: 'Chưa có phiên đặt lại mật khẩu.',
          ),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isSubmitting: true,
        clearFailure: true,
        clearCodeError: true,
        nowUtc: _clock(),
      ),
    );

    try {
      final result = _isPublic
          ? await _authRepository.verifyPasswordResetByEmail(operationId, code.trim())
          : await _authRepository.verifyMyPasswordReset(operationId, code.trim());
      if (isClosed) return;
      if (!result.verified) {
        emit(
          state.copyWith(
            isSubmitting: false,
            verified: false,
            step: PasswordResetStep.verifyCode,
            codeError: 'Mã xác nhận không đúng.',
            clearFailure: true,
            nowUtc: _clock(),
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          isSubmitting: false,
          verified: true,
          step: PasswordResetStep.createNewPassword,
          clearFailure: true,
          clearCodeError: true,
          nowUtc: _clock(),
        ),
      );
    } catch (error) {
      if (isClosed) return;
      final mapped = IamUiFailureMapper.from(error);
      final isCodeError = mapped.code == IamBlockedCodes.resetCodeInvalid ||
          mapped.code == IamBlockedCodes.resetCodeExpired ||
          mapped.code == IamBlockedCodes.resetCodeAttemptsExceeded;
      emit(
        isCodeError
            ? state.copyWith(
                isSubmitting: false,
                verified: false,
                step: PasswordResetStep.verifyCode,
                codeError: mapped.message,
                clearFailure: true,
                nowUtc: _clock(),
              )
            : state.copyWith(
                isSubmitting: false,
                verified: false,
                step: PasswordResetStep.verifyCode,
                failure: mapped,
                clearCodeError: true,
                nowUtc: _clock(),
              ),
      );
    }
  }

  Future<void> complete(String newPassword) async {
    if (isClosed || state.isSubmitting || !state.verified) return;
    final operationId = state.request?.operationId;
    if (operationId == null || operationId.isEmpty) return;

    if (!PasswordPolicy.isValid(newPassword)) {
      emit(
        state.copyWith(
          isSubmitting: false,
          failure: const IamUiFailure(
            code: IamBlockedCodes.validationError,
            message: 'PASSWORD_POLICY_VIOLATION',
          ),
          nowUtc: _clock(),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isSubmitting: true,
        clearFailure: true,
        clearCodeError: true,
        nowUtc: _clock(),
      ),
    );

    try {
      final result = _isPublic
          ? await _authRepository.completePasswordResetByEmail(operationId, newPassword)
          : await _authRepository.completeMyPasswordReset(operationId, newPassword);
      if (isClosed) return;
      emit(
        state.copyWith(
          isSubmitting: false,
          completion: result,
          clearFailure: true,
          nowUtc: _clock(),
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isSubmitting: false,
          failure: IamUiFailureMapper.from(error),
          nowUtc: _clock(),
        ),
      );
    }
  }
}
