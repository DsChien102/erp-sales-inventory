import '../iam/iam_ui_failure.dart';
import 'models/accessible_tenant.dart';
import 'models/tenant_context.dart';

enum AuthStatus { unknown, signedOut, signedIn }

enum TenantLoadStatus {
  initial,
  loading,
  ready,
  blocked,
  failure,
}

/// Các trạng thái rỗng / lỗi của giao diện tổ chức.
enum OrganizationEmptyStateType {
  noOrganizations,
  noAuthorizedOrganizations,
  inaccessible,
  noResults,
  loadError,
  unauthorized,
}

final class SessionState {
  const SessionState({
    this.authStatus = AuthStatus.unknown,
    this.userId,
    this.identityRevoked = false,
    this.status = TenantLoadStatus.initial,
    this.current,
    this.tenants = const [],
    this.branchDisplayName,
    this.userDisplayName = '',
    this.contextFailure,
    this.selectorFailure,
    this.switchFailure,
    this.blockedErrorCode,
    this.emptyStateType,
    this.suspendedOrgName,
    this.tenantsLoading = false,
    this.isSwitching = false,
    this.openSelectorRequested = false,
    this.legalProfileBannerDismissed = false,
    this.isPlatformAdmin = false,
  });

  final AuthStatus authStatus;
  final String? userId;

  /// Tài khoản bị tạm ngừng. Dashboard nghe cạnh này để đăng xuất.
  final bool identityRevoked;

  final TenantLoadStatus status;
  final TenantContext? current;
  final List<AccessibleTenant> tenants;
  final String? branchDisplayName;
  final String userDisplayName;
  final IamUiFailure? contextFailure;
  final IamUiFailure? selectorFailure;
  final IamUiFailure? switchFailure;
  final String? blockedErrorCode;
  final OrganizationEmptyStateType? emptyStateType;
  final String? suspendedOrgName;
  final bool tenantsLoading;
  final bool isSwitching;
  final bool openSelectorRequested;

  /// Banner hồ sơ pháp lý đã đóng trong phiên hiện tại.
  final bool legalProfileBannerDismissed;

  /// Người dùng có quyền `platform.tenant.view` (Platform Admin). Quyết định
  /// nhóm "Quản trị nền tảng" và guard G7; RPC vẫn tự kiểm quyền (BR-60).
  final bool isPlatformAdmin;

  bool get isValid =>
      status == TenantLoadStatus.ready && current?.status == TenantContextStatus.valid;

  bool get isBlocked => status == TenantLoadStatus.blocked;

  /// Đã đăng nhập nhưng không còn tổ chức nào chọn được.
  bool get hasNoOrganization =>
      status == TenantLoadStatus.blocked &&
      emptyStateType == OrganizationEmptyStateType.noAuthorizedOrganizations;

  SessionState copyWith({
    AuthStatus? authStatus,
    String? userId,
    bool? identityRevoked,
    bool clearIdentityRevoked = false,
    TenantLoadStatus? status,
    TenantContext? current,
    List<AccessibleTenant>? tenants,
    String? branchDisplayName,
    String? userDisplayName,
    IamUiFailure? contextFailure,
    IamUiFailure? selectorFailure,
    IamUiFailure? switchFailure,
    String? blockedErrorCode,
    OrganizationEmptyStateType? emptyStateType,
    String? suspendedOrgName,
    bool? tenantsLoading,
    bool? isSwitching,
    bool? openSelectorRequested,
    bool? legalProfileBannerDismissed,
    bool? isPlatformAdmin,
    bool clearContextFailure = false,
    bool clearSelectorFailure = false,
    bool clearSwitchFailure = false,
    bool clearCurrent = false,
    bool clearEmptyState = false,
    bool clearBranchDisplayName = false,
    bool clearBlockedErrorCode = false,
    bool clearUserId = false,
  }) {
    return SessionState(
      authStatus: authStatus ?? this.authStatus,
      userId: clearUserId ? null : (userId ?? this.userId),
      identityRevoked: clearIdentityRevoked ? false : (identityRevoked ?? this.identityRevoked),
      status: status ?? this.status,
      current: clearCurrent ? null : (current ?? this.current),
      tenants: tenants ?? this.tenants,
      branchDisplayName: clearBranchDisplayName
          ? null
          : (branchDisplayName ?? this.branchDisplayName),
      userDisplayName: userDisplayName ?? this.userDisplayName,
      contextFailure: clearContextFailure ? null : (contextFailure ?? this.contextFailure),
      selectorFailure: clearSelectorFailure ? null : (selectorFailure ?? this.selectorFailure),
      switchFailure: clearSwitchFailure ? null : (switchFailure ?? this.switchFailure),
      blockedErrorCode: clearBlockedErrorCode ? null : (blockedErrorCode ?? this.blockedErrorCode),
      emptyStateType: clearEmptyState ? null : (emptyStateType ?? this.emptyStateType),
      suspendedOrgName: clearEmptyState ? null : (suspendedOrgName ?? this.suspendedOrgName),
      tenantsLoading: tenantsLoading ?? this.tenantsLoading,
      isSwitching: isSwitching ?? this.isSwitching,
      openSelectorRequested: openSelectorRequested ?? this.openSelectorRequested,
      legalProfileBannerDismissed:
          legalProfileBannerDismissed ?? this.legalProfileBannerDismissed,
      isPlatformAdmin: isPlatformAdmin ?? this.isPlatformAdmin,
    );
  }
}
