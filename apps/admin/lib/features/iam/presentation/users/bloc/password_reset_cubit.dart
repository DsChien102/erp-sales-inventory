import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_iam_application/application.dart';

import '../../shared/iam_ui_failure.dart';
import '../../shared/iam_ui_failure_mapper.dart';
import 'password_reset_state.dart';

final class PasswordResetCubit extends Cubit<PasswordResetState> {
  PasswordResetCubit({
    required IIamModule iamModule,
    this.requestEmail,
    DateTime Function()? clock,
  }) : _iamModule = iamModule,
       _clock = clock ?? (() => DateTime.now().toUtc()),
       super(PasswordResetState(nowUtc: (clock ?? () => DateTime.now().toUtc())()));

  final IIamModule _iamModule;
  final DateTime Function() _clock;

  /// When set, use public (logged-out) reset-by-email commands.
  final String? requestEmail;

  bool get _isPublic =>
      requestEmail != null && requestEmail!.trim().isNotEmpty;

  void tick() {
    if (isClosed) return;
    emit(state.copyWith(nowUtc: _clock()));
  }

  void returnToVerify() {
    if (isClosed) return;
    emit(state.copyWith(step: PasswordResetStep.verifyCode));
  }

  Future<void> request() async {
    if (isClosed || state.isSubmitting) return;
    emit(
      state.copyWith(
        isSubmitting: true,
        clearFailure: true,
        nowUtc: _clock(),
      ),
    );

    try {
      final result =
          await _iamModule.executeCommandAsync<PasswordResetRequestResultDto>(
            _isPublic
                ? RequestPasswordResetByEmailCommand(
                    email: requestEmail!.trim(),
                  )
                : RequestMyPasswordResetCommand(),
          );
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
        nowUtc: _clock(),
      ),
    );

    try {
      final result =
          await _iamModule.executeCommandAsync<PasswordResetRequestResultDto>(
            _isPublic
                ? ResendPasswordResetByEmailCommand(operationId: operationId)
                : ResendMyPasswordResetCommand(operationId: operationId),
          );
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
        nowUtc: _clock(),
      ),
    );

    try {
      final result =
          await _iamModule.executeCommandAsync<PasswordResetVerifyResultDto>(
            _isPublic
                ? VerifyPasswordResetByEmailCommand(
                    operationId: operationId,
                    code: code.trim(),
                  )
                : VerifyMyPasswordResetCommand(
                    operationId: operationId,
                    code: code.trim(),
                  ),
          );
      if (isClosed) return;
      if (!result.verified) {
        emit(
          state.copyWith(
            isSubmitting: false,
            verified: false,
            step: PasswordResetStep.verifyCode,
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
          nowUtc: _clock(),
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          isSubmitting: false,
          verified: false,
          step: PasswordResetStep.verifyCode,
          failure: IamUiFailureMapper.from(error),
          nowUtc: _clock(),
        ),
      );
    }
  }

  Future<void> complete(String newPassword) async {
    if (isClosed || state.isSubmitting || !state.verified) return;
    final operationId = state.request?.operationId;
    if (operationId == null || operationId.isEmpty) return;

    emit(
      state.copyWith(
        isSubmitting: true,
        clearFailure: true,
        nowUtc: _clock(),
      ),
    );

    try {
      final result = await _iamModule
          .executeCommandAsync<PasswordResetCompletionResultDto>(
            _isPublic
                ? CompletePasswordResetByEmailCommand(
                    operationId: operationId,
                    newPassword: newPassword,
                  )
                : CompleteMyPasswordResetCommand(
                    operationId: operationId,
                    newPassword: newPassword,
                  ),
          );
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
