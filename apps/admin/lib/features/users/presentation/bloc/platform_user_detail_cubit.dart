import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_iam_presentation/presentation.dart';

import 'platform_user_detail_state.dart';

/// Platform user detail + lifecycle actions via [IIamModule] (EP-01 US-01/US-02).
final class PlatformUserDetailCubit extends Cubit<PlatformUserDetailState> {
  PlatformUserDetailCubit({
    required IIamModule iamModule,
    required this.userId,
    IdempotencyKeyFactory? keyFactory,
  }) : _iamModule = iamModule,
       _keyFactory = keyFactory ?? const UuidIdempotencyKeyFactory(),
       super(const PlatformUserDetailState());

  final IIamModule _iamModule;
  final IdempotencyKeyFactory _keyFactory;
  final String userId;

  String? _mutationKey;
  PlatformUserMutation? _mutationKind;
  int? _mutationVersion;

  Future<void> load() async {
    if (isClosed) return;
    emit(
      state.copyWith(
        status: IamLoadStatus.loading,
        clearFailure: true,
        clearSuccessMessage: true,
      ),
    );
    try {
      final user = await _iamModule.executeQueryAsync<PlatformUserDetailDto>(
        GetPlatformUserQuery(userId: userId),
      );
      final session = await _iamModule.executeQueryAsync<SessionDto>(
        GetCurrentSessionQuery(),
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          status: IamLoadStatus.success,
          user: user,
          permissions: _permissionsFromSession(session),
          clearFailure: true,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      final failure = IamUiFailureMapper.from(error);
      emit(
        state.copyWith(
          status: _statusForLoadFailure(failure),
          clearUser: failure.code == IamBlockedCodes.resourceNotFound,
          failure: failure,
        ),
      );
    }
  }

  Future<bool> sendActivationInvitation() {
    return _runMutation(
      mutation: PlatformUserMutation.activationInvite,
      requiredPermission: IamPlatformPermissions.userActivationInviteSend,
      allowedStatuses: const [PlatformUserStatus.pendingActivation],
      successMessage: 'Đã gửi lại email kích hoạt thành công.',
      execute: (version, key) => _iamModule.executeCommandAsync<void>(
        SendActivationInvitationCommand(
          userId: userId,
          expectedVersion: version,
          idempotencyKey: key,
        ),
      ),
    );
  }

  Future<bool> requestPasswordReset() {
    return _runMutation(
      mutation: PlatformUserMutation.passwordReset,
      requiredPermission: IamPlatformPermissions.userPasswordResetInitiate,
      allowedStatuses: const [PlatformUserStatus.active],
      successMessage: 'Đã gửi yêu cầu đặt lại mật khẩu.',
      execute: (version, key) => _iamModule.executeCommandAsync<void>(
        RequestPlatformPasswordResetCommand(
          userId: userId,
          expectedVersion: version,
          idempotencyKey: key,
        ),
      ),
    );
  }

  Future<bool> suspend({required String reason}) async {
    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      if (isClosed) return false;
      emit(
        state.copyWith(
          failure: const IamUiFailure(
            code: IamBlockedCodes.validationError,
            message: 'Vui lòng nhập lý do tạm ngừng.',
          ),
          clearSuccessMessage: true,
        ),
      );
      return false;
    }
    return _runMutation(
      mutation: PlatformUserMutation.suspend,
      requiredPermission: IamPlatformPermissions.userSuspend,
      allowedStatuses: const [
        PlatformUserStatus.active,
        PlatformUserStatus.pendingActivation,
      ],
      successMessage: 'Đã tạm ngừng tài khoản thành công.',
      execute: (version, key) => _iamModule.executeCommandAsync<void>(
        SuspendPlatformUserCommand(
          userId: userId,
          reason: trimmed,
          expectedVersion: version,
          idempotencyKey: key,
        ),
      ),
    );
  }

  Future<bool> restore() {
    return _runMutation(
      mutation: PlatformUserMutation.restore,
      requiredPermission: IamPlatformPermissions.userRestore,
      allowedStatuses: const [PlatformUserStatus.suspended],
      successMessage: 'Đã khôi phục tài khoản thành công.',
      execute: (version, key) => _iamModule.executeCommandAsync<void>(
        RestorePlatformUserCommand(
          userId: userId,
          expectedVersion: version,
          idempotencyKey: key,
        ),
      ),
    );
  }

  void clearFeedback() {
    if (isClosed) return;
    emit(
      state.copyWith(
        clearFailure: true,
        clearSuccessMessage: true,
      ),
    );
  }

  Future<bool> _runMutation({
    required PlatformUserMutation mutation,
    required String requiredPermission,
    required List<PlatformUserStatus> allowedStatuses,
    required String successMessage,
    required Future<void> Function(int version, String key) execute,
  }) async {
    if (isClosed || state.isSubmitting) return false;
    final user = state.user;
    if (user == null) return false;
    if (!state.hasPermission(requiredPermission)) {
      emit(
        state.copyWith(
          failure: const IamUiFailure(
            code: IamBlockedCodes.platformPermissionDenied,
            message: 'Bạn không có quyền thực hiện thao tác này.',
          ),
          clearSuccessMessage: true,
        ),
      );
      return false;
    }
    if (!allowedStatuses.contains(user.status)) {
      emit(
        state.copyWith(
          failure: const IamUiFailure(
            code: IamBlockedCodes.tenantStateInvalid,
            message: 'Trạng thái người dùng không cho phép thao tác này.',
          ),
          clearSuccessMessage: true,
        ),
      );
      return false;
    }

    final version = user.version;
    final key = _keyFor(mutation, version);
    emit(
      state.copyWith(
        isSubmitting: true,
        activeMutation: mutation,
        clearFailure: true,
        clearSuccessMessage: true,
      ),
    );

    try {
      await execute(version, key);
      if (isClosed) return false;
      _clearMutationKey();
      await load();
      if (isClosed) return false;
      emit(
        state.copyWith(
          isSubmitting: false,
          clearActiveMutation: true,
          successMessage: successMessage,
          clearFailure: true,
        ),
      );
      return true;
    } catch (error) {
      if (isClosed) return false;
      final failure = IamUiFailureMapper.from(error);
      if (failure.code == IamBlockedCodes.stateChanged) {
        _clearMutationKey();
        await load();
        if (isClosed) return false;
        emit(
          state.copyWith(
            isSubmitting: false,
            clearActiveMutation: true,
            failure: failure,
            clearSuccessMessage: true,
          ),
        );
        return false;
      }
      emit(
        state.copyWith(
          isSubmitting: false,
          clearActiveMutation: true,
          failure: failure,
          clearSuccessMessage: true,
        ),
      );
      return false;
    }
  }

  String _keyFor(PlatformUserMutation mutation, int version) {
    if (_mutationKey != null &&
        _mutationKind == mutation &&
        _mutationVersion == version) {
      return _mutationKey!;
    }
    _mutationKind = mutation;
    _mutationVersion = version;
    _mutationKey = _keyFactory.next(mutation.name);
    return _mutationKey!;
  }

  void _clearMutationKey() {
    _mutationKey = null;
    _mutationKind = null;
    _mutationVersion = null;
  }

  static IamLoadStatus _statusForLoadFailure(IamUiFailure failure) {
    if (failure.code == IamBlockedCodes.resourceNotFound) {
      return IamLoadStatus.empty;
    }
    if (failure.code == IamBlockedCodes.platformPermissionDenied) {
      return IamLoadStatus.unauthorized;
    }
    return IamLoadStatus.failure;
  }

  static List<String> _permissionsFromSession(SessionDto session) {
    if (session.role == 'owner') {
      return const ['__owner__'];
    }
    return List<String>.of(session.permissions);
  }
}
