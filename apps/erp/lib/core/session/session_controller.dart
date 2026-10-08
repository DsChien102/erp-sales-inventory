import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_iam_infrastructure/infrastructure.dart';
import 'package:erp/features/iam/presentation.dart';
import 'package:vet45_shared_application/application.dart';

import '../../features/tenant_context/presentation/mappers/accessible_tenant_ui_mapper.dart';
import '../errors/app_exception.dart';
import 'session_state.dart';

/// Một nguồn sự thật về phiên đăng nhập và tổ chức đang chọn.
///
/// Thân bootstrap / đổi tổ chức vẫn gọi IAM module cũ.
/// TODO(2-A2): đổi sang RPC `iam.get_tenant_context`, `list_accessible_tenants`,
/// `switch_tenant_context` khi chuyển IAM.
final class SessionController extends Cubit<SessionState> {
  SessionController({
    required IIamModule iamModule,
    GoTrueClient? auth,
    IamSession? iamSession,
    IIamSessionPort? sessionPort,
    String userDisplayName = '',
    SessionState? initialState,
    Stream<String>? tenantAccessRevoked,
  }) : _iamModule = iamModule,
       _auth = auth,
       _iamSession = iamSession,
       _sessionPort = sessionPort,
       super(
         initialState ?? SessionState(userDisplayName: userDisplayName),
       ) {
    _revokedSubscription = (tenantAccessRevoked ?? TenantAccessRevokedSignal.stream).listen(
      _onTenantAccessRevoked,
    );
  }

  final IIamModule _iamModule;
  final GoTrueClient? _auth;
  final IamSession? _iamSession;
  final IIamSessionPort? _sessionPort;
  late final StreamSubscription<String> _revokedSubscription;
  StreamSubscription<AuthState>? _authSub;

  /// Gọi 1 lần trong initDependencies (thay restorePersistedAuthSession).
  void start() {
    final auth = _auth;
    final sessionPort = _sessionPort;
    if (auth == null || sessionPort == null) {
      throw StateError('SessionController.start() cần auth và sessionPort');
    }
    _apply(auth.currentUser?.id);
    _authSub = auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.signedOut) {
        _apply(null);
      }
      if (event.event == AuthChangeEvent.signedIn ||
          event.event == AuthChangeEvent.tokenRefreshed) {
        _apply(event.session?.user.id);
      }
    });
  }

  void _apply(String? userId) {
    final trimmed = userId?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      _sessionPort?.clear();
      emit(const SessionState(authStatus: AuthStatus.signedOut));
      return;
    }
    // Supabase phát signedIn cả khi app quay lại foreground.
    if (state.userId != trimmed) {
      _sessionPort?.applyAuthenticatedUser(trimmed);
    }
    if (state.authStatus == AuthStatus.signedIn && state.userId == trimmed) {
      return;
    }
    emit(
      state.copyWith(
        authStatus: AuthStatus.signedIn,
        userId: trimmed,
        clearIdentityRevoked: true,
      ),
    );
  }

  String? get tenantId => _iamSession?.tenantId;

  String? get activeStoreId => _iamSession?.activeStoreId;

  bool hasPermission(String code) => _iamSession?.hasPermission(code) ?? false;

  Future<String> requireTenantId() async {
    final id = tenantId?.trim();
    if (id == null || id.isEmpty) {
      throw const AppException(AppErrorCode.authRequired);
    }
    return id;
  }

  Future<String> requireActiveStoreId() {
    final session = _iamSession;
    if (session == null) {
      throw const AppException(AppErrorCode.authRequired);
    }
    return session.requireActiveStoreId();
  }

  /// Thay guard(SignOutCommand). Trả kết quả để UI hiện cảnh báo như cũ.
  /// TODO(2-A2): gọi đăng xuất trực tiếp, không qua SignOutCommand.
  Future<SignOutResultDto> signOut() async {
    try {
      final result = await _iamModule.executeCommandAsync<SignOutResultDto>(
        SignOutCommand(),
      );
      if (result.localCleared) {
        emit(const SessionState(authStatus: AuthStatus.signedOut));
      }
      return result;
    } catch (error) {
      throw AppException.from(error);
    }
  }

  void _onTenantAccessRevoked(String code) {
    if (isClosed) return;
    if (code == TenantAccessRevokedSignal.platformUserSuspended) {
      emit(state.copyWith(identityRevoked: true));
      return;
    }
    if (state.status != TenantLoadStatus.ready) return;
    bootstrap();
  }

  @override
  Future<void> close() {
    // Do not await cancel(): broadcast cancel can hang under flutter_test fake async.
    _revokedSubscription.cancel();
    _authSub?.cancel();
    return super.close();
  }

  Future<void> bootstrap() async {
    if (isClosed) return;
    emit(
      state.copyWith(
        status: TenantLoadStatus.loading,
        clearContextFailure: true,
        clearBlockedErrorCode: true,
        clearSelectorFailure: true,
        clearSwitchFailure: true,
        clearEmptyState: true,
        clearIdentityRevoked: true,
        openSelectorRequested: false,
      ),
    );

    try {
      // TODO(2-A2): iam.get_tenant_context
      final context = await _iamModule.executeQueryAsync<TenantContextDto>(
        GetTenantContextQuery(bootstrapFromLastSelected: true),
      );
      if (isClosed) return;

      await loadAccessibleTenants();
      if (isClosed) return;

      _emitResolvedContext(context);
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: TenantLoadStatus.failure,
          contextFailure: IamUiFailureMapper.from(error),
        ),
      );
    }
  }

  Future<void> loadAccessibleTenants() async {
    if (isClosed) return;
    final keepStatus = state.status;
    emit(
      state.copyWith(
        tenantsLoading: true,
        clearSelectorFailure: true,
      ),
    );

    try {
      // TODO(2-A2): iam.list_accessible_tenants
      final dtos = await _iamModule.executeQueryAsync<List<AccessibleTenantDto>>(
        ListAccessibleTenantsQuery(),
      );
      if (isClosed) return;

      emit(
        state.copyWith(
          status: keepStatus,
          tenants: AccessibleTenantUiMapper.fromList(dtos),
          tenantsLoading: false,
          clearSelectorFailure: true,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: keepStatus,
          tenants: const [],
          tenantsLoading: false,
          selectorFailure: IamUiFailureMapper.from(error),
        ),
      );
    }
  }

  /// Returns `true` when switch succeeds. Confirmation is UI-only.
  Future<bool> switchTo(String tenantId) async {
    if (isClosed) return false;
    emit(
      state.copyWith(
        isSwitching: true,
        clearSwitchFailure: true,
      ),
    );

    try {
      // TODO(2-A2): iam.switch_tenant_context
      final context = await _iamModule.executeCommandAsync<TenantContextDto>(
        SwitchTenantContextCommand(targetTenantId: tenantId),
      );
      if (isClosed) return false;

      await loadAccessibleTenants();
      if (isClosed) return false;

      _applyTenantContextPermissions(context);

      emit(
        state.copyWith(
          status: TenantLoadStatus.ready,
          current: context,
          branchDisplayName: context.tenantName,
          isSwitching: false,
          openSelectorRequested: false,
          clearEmptyState: true,
          clearSwitchFailure: true,
          clearContextFailure: true,
          clearBlockedErrorCode: true,
        ),
      );
      return true;
    } catch (error) {
      if (isClosed) return false;
      final failure = _mapFailure(error);
      emit(
        state.copyWith(
          isSwitching: false,
          switchFailure: failure,
        ),
      );

      if (_shouldReloadTenantsAfterSwitchFailure(failure)) {
        await loadAccessibleTenants();
      }
      return false;
    }
  }

  void consumeOpenSelectorRequest() {
    if (isClosed || !state.openSelectorRequested) return;
    emit(state.copyWith(openSelectorRequested: false));
  }

  void requestOpenSelector() {
    if (isClosed) return;
    emit(state.copyWith(openSelectorRequested: true));
  }

  /// Empty-state for the selector sheet: loadError wins over empty list.
  OrganizationEmptyStateType? get selectorEmptyStateType {
    if (state.selectorFailure != null) {
      return OrganizationEmptyStateType.loadError;
    }
    if (state.tenants.isEmpty) {
      return OrganizationEmptyStateType.noAuthorizedOrganizations;
    }
    return null;
  }

  /// Retry load for selector sheet. Returns tenants on success, `null` on fail.
  Future<List<SelectOrganizationItemUiModel>?> retryLoadAccessibleTenants() async {
    await loadAccessibleTenants();
    if (isClosed) return null;
    if (state.selectorFailure != null) return null;
    return state.tenants;
  }

  void _applyTenantContextPermissions(TenantContextDto context) {
    final session = _iamSession;
    if (session == null) return;
    final userId = session.userId;
    final tenantId = context.tenantId;
    if (userId == null || userId.isEmpty || tenantId == null || tenantId.isEmpty) {
      return;
    }
    session.apply(
      PrincipalAccessDto(
        userId: userId,
        tenantId: tenantId,
        role: context.roleLabel ?? session.role ?? '',
        isOwner: context.isOwner,
        permissions: context.permissions,
      ),
    );
  }

  IamUiFailure _mapFailure(Object error) {
    if (error is ApplicationException) {
      final trimmed = error.message.trim();
      if (trimmed.isNotEmpty && trimmed == trimmed.toUpperCase() && trimmed.contains('_')) {
        return IamUiFailure(code: trimmed, message: trimmed);
      }
    }
    return IamUiFailureMapper.from(error);
  }

  bool _shouldReloadTenantsAfterSwitchFailure(IamUiFailure failure) {
    return failure.code == IamBlockedCodes.tenantSuspended ||
        failure.code == IamBlockedCodes.tenantClosed;
  }

  void _emitResolvedContext(TenantContextDto context) {
    if (context.status == TenantContextStatus.valid) {
      _applyTenantContextPermissions(context);
    }
    final identityRevoked =
        context.blockedErrorCode == IamBlockedCodes.platformUserSuspended ||
        context.invalidationReason == TenantContextInvalidationReason.identityInactive;
    switch (context.status) {
      case TenantContextStatus.valid:
        emit(
          state.copyWith(
            status: TenantLoadStatus.ready,
            current: context,
            branchDisplayName: context.tenantName,
            clearEmptyState: true,
            clearContextFailure: true,
            clearBlockedErrorCode: true,
            openSelectorRequested: false,
          ),
        );
        break;
      case TenantContextStatus.none:
        emit(
          state.copyWith(
            status: TenantLoadStatus.blocked,
            current: context,
            clearBranchDisplayName: true,
            emptyStateType: OrganizationEmptyStateType.noAuthorizedOrganizations,
            openSelectorRequested: true,
            clearContextFailure: true,
            clearBlockedErrorCode: true,
          ),
        );
        break;
      case TenantContextStatus.invalidated:
        final inaccessible =
            context.invalidationReason == TenantContextInvalidationReason.tenantSuspended ||
            context.invalidationReason == TenantContextInvalidationReason.tenantClosed ||
            context.invalidationReason == TenantContextInvalidationReason.identityInactive ||
            context.blockedErrorCode == IamBlockedCodes.tenantSuspended ||
            context.blockedErrorCode == IamBlockedCodes.tenantClosed ||
            context.blockedErrorCode == IamBlockedCodes.platformUserSuspended;
        emit(
          state.copyWith(
            status: TenantLoadStatus.blocked,
            current: context,
            clearBranchDisplayName: true,
            blockedErrorCode: context.blockedErrorCode,
            emptyStateType: inaccessible
                ? OrganizationEmptyStateType.inaccessible
                : OrganizationEmptyStateType.noAuthorizedOrganizations,
            suspendedOrgName: context.tenantName,
            openSelectorRequested: true,
            clearContextFailure: true,
            identityRevoked: identityRevoked ? true : null,
          ),
        );
        break;
    }
  }
}
