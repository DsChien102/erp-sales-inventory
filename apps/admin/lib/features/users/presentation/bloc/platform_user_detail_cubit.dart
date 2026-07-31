import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import 'platform_user_detail_state.dart';

/// Platform user detail + lifecycle actions via [IIamModule] (EP-01 US-01/US-02).
final class PlatformUserDetailCubit extends Cubit<PlatformUserDetailState> {
  PlatformUserDetailCubit({required IIamModule iamModule, required this.userId})
    : _iamModule = iamModule,
      super(const PlatformUserDetailState());

  final IIamModule _iamModule;
  final String userId;

  Future<void> load() async {
    if (isClosed) return;
    emit(
      state.copyWith(
        status: PlatformUserDetailStatus.loading,
        clearMessages: true,
      ),
    );
    try {
      final user = await _iamModule.executeQueryAsync<PlatformUserDetailDto>(
        GetPlatformUserQuery(userId: userId),
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          status: PlatformUserDetailStatus.success,
          user: user,
          clearMessages: true,
        ),
      );
    } on ValidationException catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: PlatformUserDetailStatus.notFound,
          errorMessage: e.message,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      final message = e.toString();
      final notFound = message.toLowerCase().contains('not found');
      emit(
        state.copyWith(
          status: notFound
              ? PlatformUserDetailStatus.notFound
              : PlatformUserDetailStatus.failure,
          errorMessage: message,
        ),
      );
    }
  }

  Future<bool> suspend({required String reason}) async {
    final version = state.user?.version ?? 1;
    return _runMutation(
      () => _iamModule.executeCommandAsync<void>(
        SuspendPlatformUserCommand(
          userId: userId,
          reason: reason,
          expectedVersion: version,
          idempotencyKey: 'suspend-$userId-$version',
        ),
      ),
      successMessage: 'Đã tạm ngừng tài khoản thành công.',
    );
  }

  Future<bool> restore() async {
    final version = state.user?.version ?? 1;
    return _runMutation(
      () => _iamModule.executeCommandAsync<void>(
        RestorePlatformUserCommand(
          userId: userId,
          expectedVersion: version,
          idempotencyKey: 'restore-$userId-$version',
        ),
      ),
      successMessage: 'Đã khôi phục tài khoản thành công.',
    );
  }

  Future<bool> sendActivationInvitation() async {
    final version = state.user?.version ?? 1;
    return _runMutation(
      () => _iamModule.executeCommandAsync<void>(
        SendActivationInvitationCommand(
          userId: userId,
          expectedVersion: version,
          idempotencyKey: 'activate-$userId-$version',
        ),
      ),
      successMessage: 'Đã gửi lại email kích hoạt thành công.',
    );
  }

  Future<bool> _runMutation(
    Future<void> Function() action, {
    required String successMessage,
  }) async {
    if (isClosed) return false;
    emit(state.copyWith(isSubmitting: true, clearMessages: true));
    try {
      await action();
      if (isClosed) return false;
      await load();
      if (isClosed) return false;
      emit(state.copyWith(isSubmitting: false, successMessage: successMessage));
      return true;
    } catch (e) {
      if (isClosed) return false;
      emit(state.copyWith(isSubmitting: false, errorMessage: e.toString()));
      return false;
    }
  }

  void clearMessages() {
    emit(state.copyWith(clearMessages: true));
  }
}
