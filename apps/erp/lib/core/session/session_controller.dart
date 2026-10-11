import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vet45_shared_application/application.dart';

import '../errors/app_exception.dart';
import '../iam/iam_codes.dart';
import '../iam/iam_ui_failure.dart';
import '../iam/iam_ui_failure_mapper.dart';
import 'models/accessible_tenant.dart';
import 'models/session_principal.dart';
import 'models/session_snapshot.dart';
import 'models/sign_out_result.dart';
import 'models/tenant_context.dart';
import 'session_repository.dart';
import 'session_state.dart';
import 'session_store.dart';

/// Một nguồn sự thật về phiên đăng nhập và tổ chức đang chọn.
///
/// Ghi vào [SessionStore]; module nghiệp vụ cũ đọc tenant / cửa hàng qua
/// `CoreExecutionContext` / `CorePermissionChecker` cùng store này.
final class SessionController extends Cubit<SessionState> {
  SessionController({
    required SessionRepository repository,
    GoTrueClient? auth,
    SessionStore? store,
    String userDisplayName = '',
    SessionState? initialState,
    Stream<String>? tenantAccessRevoked,
    DateTime Function()? clock,
  }) : _repository = repository,
       _auth = auth,
       _store = store ?? SessionStore(repository: repository),
       _clock = clock ?? DateTime.now,
       super(
         initialState ?? SessionState(userDisplayName: userDisplayName),
       ) {
    _revokedSubscription = (tenantAccessRevoked ?? TenantAccessRevokedSignal.stream).listen(
      _onTenantAccessRevoked,
    );
  }

  final SessionRepository _repository;
  final GoTrueClient? _auth;
  final SessionStore _store;
  final DateTime Function() _clock;
  late final StreamSubscription<String> _revokedSubscription;
  StreamSubscription<AuthState>? _authSub;
  DateTime? _lastRecheckAt;
  bool _holdSignedIn = false;

  static const _platformReadPermission = 'platform.tenant.view';

  /// Gọi 1 lần trong initDependencies.
  void start() {
    final auth = _auth;
    if (auth == null) {
      throw StateError('SessionController.start() cần auth');
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

  /// Gắn user ngay sau `signIn`, không chờ `onAuthStateChange`.
  void applySignedInUser(String userId) {
    _holdSignedIn = false;
    _apply(userId);
  }

  /// Giữ trạng thái `signedIn` lại đến [applySignedInUser].
  ///
  /// OTP đăng ký làm `onAuthStateChange` phát `signedIn` trước khi app kịp
  /// ghi lại mật khẩu. Guard G2 sẽ đưa `/signup` về `/` nếu gắn phiên ngay.
  void holdSignedInApply() {
    _holdSignedIn = true;
  }

  /// Bỏ giữ phiên khi xác minh thất bại, không gắn user đang chờ.
  void releaseSignedInHold() {
    _holdSignedIn = false;
  }

  /// Ẩn banner hồ sơ pháp lý đến hết phiên, hoặc đến khi đổi người dùng / tổ chức.
  void dismissLegalProfileBanner() {
    if (isClosed || state.legalProfileBannerDismissed) return;
    emit(state.copyWith(legalProfileBannerDismissed: true));
  }

  void _apply(String? userId) {
    final trimmed = userId?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      _holdSignedIn = false;
      _store.clear();
      emit(const SessionState(authStatus: AuthStatus.signedOut));
      return;
    }
    if (_holdSignedIn) return;
    final previous = state.userId;
    if (previous != null && previous != trimmed) {
      _store.applyAuthenticatedUser(trimmed);
      emit(
        SessionState(
          authStatus: AuthStatus.signedIn,
          userId: trimmed,
          userDisplayName: state.userDisplayName,
        ),
      );
      return;
    }
    // Bootstrap lúc đang giữ phiên (đăng ký) đã gắn đúng user này vào store;
    // gọi lại applyAuthenticatedUser sẽ xoá tenant / cửa hàng vừa nạp.
    if (previous != trimmed && _store.userId != trimmed) {
      _store.applyAuthenticatedUser(trimmed);
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

  String? get tenantId => _store.tenantId;

  String? get activeStoreId => _store.activeStoreId;

  String? get activeStoreCode => _store.activeStoreCode;

  String? get activeStoreDisplayName => _store.activeStoreDisplayName;

  bool hasPermission(String code) => _store.hasPermission(code);

  String? get role => _blankToNull(_store.role);

  bool get isOwner => _store.isOwner;

  String? get email => _auth?.currentUser?.email;

  List<String> get permissions => _store.permissions.toList(growable: false);

  /// Ảnh phiên mà hub IAM đang đọc (`SessionSnapshot.hasPermission` = owner hoặc quyền).
  /// Hết hạn token thì ném [AppException] `SESSION_EXPIRED`.
  SessionSnapshot readSession() {
    final auth = _auth;
    if (auth != null) {
      final current = auth.currentSession;
      if (current == null) return const SessionSnapshot(isAuthenticated: false);
      if (current.isExpired) {
        throw const AppException('SESSION_EXPIRED');
      }
    } else if (state.authStatus != AuthStatus.signedIn) {
      return const SessionSnapshot(isAuthenticated: false);
    }

    final userId = _blankToNull(_store.userId) ?? _blankToNull(state.userId);
    if (userId == null) return const SessionSnapshot(isAuthenticated: false);
    return SessionSnapshot(
      isAuthenticated: true,
      userId: userId,
      email: email,
      tenantId: _blankToNull(_store.tenantId),
      activeStoreId: _blankToNull(_store.activeStoreId),
      role: role,
      isOwner: isOwner,
      permissions: permissions,
    );
  }

  static String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  Future<String> requireTenantId() async {
    final id = tenantId?.trim();
    if (id == null || id.isEmpty) {
      throw const AppException(AppErrorCode.authRequired);
    }
    return id;
  }

  /// Cửa hàng đang hoạt động; trống thì nạp lại từ server (xem [SessionStore]).
  Future<String> requireActiveStoreId() => _store.requireActiveStoreId();

  /// Đăng xuất Supabase rồi xoá phiên cục bộ. Lỗi máy chủ không chặn xoá local.
  Future<SignOutResult> signOut() async {
    var remote = false;
    try {
      await _auth?.signOut();
      remote = _auth != null;
    } catch (_) {
      remote = false;
    } finally {
      _store.clear();
    }
    emit(const SessionState(authStatus: AuthStatus.signedOut));
    return SignOutResult(localCleared: true, remoteSucceeded: remote);
  }

  void _onTenantAccessRevoked(String code) {
    if (isClosed) return;
    if (code == TenantAccessRevokedSignal.platformUserSuspended) {
      emit(state.copyWith(identityRevoked: true));
      return;
    }
    if (code == TenantAccessRevokedSignal.permissionDenied) {
      unawaited(_recheckMembership());
      return;
    }
    if (state.status != TenantLoadStatus.ready) return;
    bootstrap();
  }

  /// `PERMISSION_DENIED` vừa có thể là quyền thường, vừa có thể là thành viên
  /// vừa bị loại. Chỉ tải lại phiên khi ngữ cảnh tổ chức không còn hợp lệ,
  /// và không kiểm dày hơn 30 giây.
  Future<void> _recheckMembership() async {
    if (isClosed || state.status != TenantLoadStatus.ready) return;
    final currentTenantId = _blankToNull(tenantId);
    if (currentTenantId == null) return;
    final now = _clock();
    final last = _lastRecheckAt;
    if (last != null && now.difference(last) < const Duration(seconds: 30)) {
      return;
    }
    _lastRecheckAt = now;
    try {
      final context = await _repository.getTenantContext(currentTenantId);
      if (isClosed || context.status == TenantContextStatus.valid) return;
      await bootstrap();
    } catch (_) {
      // Lỗi mạng không được đá người dùng khỏi tổ chức.
    }
  }

  @override
  Future<void> close() {
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

    final platformAdmin = _resolvePlatformAdmin();
    try {
      final context = await _bootstrapFromLastSelected();
      if (isClosed) return;

      await loadAccessibleTenants();
      if (isClosed) return;

      // Trước khi emit ngữ cảnh: guard G5 cần biết admin không có tổ chức.
      final isPlatformAdmin = await platformAdmin;
      if (isClosed) return;
      if (isPlatformAdmin != state.isPlatformAdmin) {
        emit(state.copyWith(isPlatformAdmin: isPlatformAdmin));
      }

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

  /// Chạy song song với việc nạp tổ chức. Lỗi → `false`, không chặn đăng nhập.
  /// Đổi người dùng khi đang chờ → `false` (kết quả của người cũ bị bỏ).
  Future<bool> _resolvePlatformAdmin() async {
    final userId = state.userId;
    try {
      final allowed = await _repository.hasPlatformPermission(_platformReadPermission);
      return allowed && state.userId == userId;
    } catch (_) {
      return false;
    }
  }

  Future<TenantContext> _bootstrapFromLastSelected() async {
    final lastSelected = _blankToNull(await _repository.getLastSelectedTenantId());
    final bootstrapId = lastSelected ?? _blankToNull(tenantId);
    if (bootstrapId != null) {
      final context = await _repository.getTenantContext(bootstrapId);
      if (_isSuspendedOrClosed(context)) return context;
      if (context.status == TenantContextStatus.valid && context.tenantId != null) {
        return _adoptTenant(context, remember: lastSelected == null);
      }
    }
    return _fallbackAccessibleTenant();
  }

  /// Không có tổ chức chọn gần nhất hợp lệ: lấy tổ chức chọn được đầu tiên.
  /// Chỉ còn tổ chức tạm ngừng / đã đóng thì trả ngữ cảnh invalidated (ID-09).
  Future<TenantContext> _fallbackAccessibleTenant() async {
    final tenants = await _repository.listAccessibleTenants();
    if (tenants.isEmpty) return TenantContext.none;

    final selectable = tenants.where((tenant) => tenant.isSelectable);
    if (selectable.isNotEmpty) {
      final picked = await _repository.getTenantContext(selectable.first.id);
      if (_isSuspendedOrClosed(picked)) return picked;
      if (picked.status == TenantContextStatus.valid && picked.tenantId != null) {
        return _adoptTenant(picked, remember: true);
      }
    }

    if (tenants.every((tenant) => !tenant.isSelectable)) {
      final first = tenants.first;
      final context = await _repository.getTenantContext(first.id);
      if (context.status == TenantContextStatus.invalidated) return context;
      final closed = first.status == TenantStatus.closed;
      return TenantContext(
        status: TenantContextStatus.invalidated,
        tenantId: first.id,
        tenantName: first.name,
        tenantStatus: first.status,
        invalidationReason: closed
            ? TenantContextInvalidationReason.tenantClosed
            : TenantContextInvalidationReason.tenantSuspended,
        blockedErrorCode: closed ? 'TENANT_CLOSED' : 'TENANT_SUSPENDED',
      );
    }

    return TenantContext.none;
  }

  bool _isSuspendedOrClosed(TenantContext context) {
    return context.status == TenantContextStatus.invalidated &&
        (context.invalidationReason == TenantContextInvalidationReason.tenantSuspended ||
            context.invalidationReason == TenantContextInvalidationReason.tenantClosed);
  }

  Future<TenantContext> _adoptTenant(TenantContext context, {required bool remember}) async {
    await _bindSession(context.tenantId!);
    if (remember) {
      await _repository.setLastSelectedTenantId(context.tenantId);
    }
    return context;
  }

  Future<void> _bindSession(String tenantId) async {
    final principal = await _repository.getSessionContext(tenantId);
    final storeId = principal?.activeStoreId?.trim();
    if (principal == null || storeId == null || storeId.isEmpty) {
      throw const AppException(
        AppErrorCode.unknown,
        serverMessage: 'Active store context is required.',
      );
    }
    _store.apply(principal);
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
      final tenants = await _repository.listAccessibleTenants(currentTenantId: tenantId);
      if (isClosed) return;

      emit(
        state.copyWith(
          status: keepStatus,
          tenants: tenants,
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
  Future<bool> switchTo(String targetTenantId) async {
    if (isClosed) return false;
    emit(
      state.copyWith(
        isSwitching: true,
        clearSwitchFailure: true,
      ),
    );

    try {
      final previousTenantId = tenantId;
      final current = previousTenantId?.trim();
      if (current != null && current.isNotEmpty && targetTenantId.trim() == current) {
        throw const AppException(
          AppErrorCode.validation,
          serverMessage: 'Target tenant must differ from the current tenant context',
        );
      }

      final context = await _repository.switchTenantContext(targetTenantId);
      if (context.status != TenantContextStatus.valid || context.tenantId == null) {
        throw AppException(context.blockedErrorCode ?? 'TENANT_ACCESS_DENIED');
      }

      try {
        await _bindSession(context.tenantId!);
      } catch (error) {
        throw _mapSwitchSessionError(error);
      }

      try {
        await _repository.setLastSelectedTenantId(context.tenantId);
      } catch (_) {
        final prior = previousTenantId?.trim();
        if (prior != null && prior.isNotEmpty) {
          try {
            await _bindSession(prior);
          } catch (_) {}
        }
        throw const AppException(AppErrorCode.unknown);
      }

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
          legalProfileBannerDismissed: false,
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
  Future<List<AccessibleTenant>?> retryLoadAccessibleTenants() async {
    await loadAccessibleTenants();
    if (isClosed) return null;
    if (state.selectorFailure != null) return null;
    return state.tenants;
  }

  void _applyTenantContextPermissions(TenantContext context) {
    final userId = _store.userId;
    final tenantId = context.tenantId;
    if (userId == null || userId.isEmpty || tenantId == null || tenantId.isEmpty) {
      return;
    }
    _store.apply(
      SessionPrincipal(
        userId: userId,
        tenantId: tenantId,
        activeStoreId: _store.activeStoreId,
        activeStoreCode: _store.activeStoreCode,
        activeStoreDisplayName: _store.activeStoreDisplayName,
        role: context.roleLabel ?? _store.role ?? '',
        isOwner: context.isOwner,
        permissions: context.permissions,
      ),
    );
  }

  AppException _mapSwitchSessionError(Object error) {
    if (error is AppException) {
      final code = _knownSwitchCode(error);
      if (code != null) return AppException(code);
    }
    return const AppException(AppErrorCode.unknown);
  }

  String? _knownSwitchCode(AppException error) {
    final message = error.code.trim();
    const knownCodes = <String>{
      IamBlockedCodes.contextInvalid,
      IamBlockedCodes.membershipInactive,
      IamBlockedCodes.membershipRemoved,
      'TENANT_ACCESS_DENIED',
      'TENANT_SUSPENDED',
      'TENANT_CLOSED',
      'NOT_AUTHENTICATED',
    };
    if (knownCodes.contains(message)) return message;

    final lower = '${error.code} ${error.serverMessage ?? ''} ${error.cause}'.toLowerCase();
    if (lower.contains('context_invalid')) return IamBlockedCodes.contextInvalid;
    if (lower.contains('membership_inactive')) return IamBlockedCodes.membershipInactive;
    if (lower.contains('membership_removed')) return IamBlockedCodes.membershipRemoved;
    if (lower.contains('tenant_access_denied')) return 'TENANT_ACCESS_DENIED';
    return null;
  }

  IamUiFailure _mapFailure(Object error) {
    if (error is AppException) {
      if (error.code == AppErrorCode.validation &&
          error.serverMessage != null &&
          error.serverMessage!.trim().isNotEmpty) {
        return IamUiFailure(
          code: error.code,
          message: error.serverMessage!.trim(),
        );
      }
      final trimmed = error.code.trim();
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

  void _emitResolvedContext(TenantContext context) {
    if (context.status == TenantContextStatus.valid) {
      _applyTenantContextPermissions(context);
    }
    final tenantChanged = state.current?.tenantId != context.tenantId;
    final keepBanner = !tenantChanged && state.legalProfileBannerDismissed;
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
            legalProfileBannerDismissed: keepBanner,
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
