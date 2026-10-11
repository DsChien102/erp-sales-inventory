import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/session/models/accessible_tenant.dart';
import 'package:erp/core/session/models/session_principal.dart';
import 'package:erp/core/session/models/tenant_context.dart';
import 'package:erp/core/session/session_repository.dart';
import '../../features/iam/support/fake_iam_backend.dart';

/// RPC phiên giả theo [FakeIamScenario] cho các kịch bản EP-05.
class FakeSessionRepository implements SessionRepository {
  FakeSessionRepository({
    this.scenario = FakeIamScenario.usersSearchOk,
    this.failGetSession = false,
    this.failSetLastSelected = false,
    this.noTenants = false,
    this.suspendedOnly = false,
    this.platformAdmin = false,
  }) {
    _seed();
  }

  final FakeIamScenario scenario;
  final bool noTenants;
  final bool suspendedOnly;
  bool failNextList = false;
  bool failGetSession;
  bool failSetLastSelected;

  /// `has_platform_permission` trả `true` khi bật; `failHasPlatformPermission` làm RPC lỗi.
  bool platformAdmin;
  bool failHasPlatformPermission = false;
  final List<String> platformPermissionChecks = [];

  String? lastSelectedTenantId;
  int switchCount = 0;
  int tenantContextReads = 0;
  int sessionContextReads = 0;
  Object? switchError;

  final List<AccessibleTenant> _tenants = [];
  final Map<String, TenantContext> _contexts = {};

  @override
  Future<bool> hasPlatformPermission(String permission) async {
    platformPermissionChecks.add(permission);
    if (failHasPlatformPermission) {
      throw const AppException(AppErrorCode.unknown);
    }
    return platformAdmin;
  }

  /// `iam.has_permission`: trả `true` khi [permissionGranted] bật.
  bool permissionGranted = true;
  final List<({String tenantId, String permission})> permissionChecks = [];

  @override
  Future<bool> hasPermission(String tenantId, String permission) async {
    permissionChecks.add((tenantId: tenantId, permission: permission));
    return permissionGranted;
  }

  @override
  Future<String?> getLastSelectedTenantId() async => lastSelectedTenantId;

  @override
  Future<void> setLastSelectedTenantId(String? tenantId) async {
    if (failSetLastSelected) {
      throw const AppException(AppErrorCode.unknown);
    }
    lastSelectedTenantId = tenantId;
  }

  /// Khi khác null, `getTenantContext` trả đúng giá trị này.
  TenantContext? overrideContext;

  @override
  Future<TenantContext> getTenantContext(String? tenantId) async {
    tenantContextReads++;
    if (tenantId == null) return TenantContext.none;
    final forced = overrideContext;
    if (forced != null) return forced;
    if (scenario == FakeIamScenario.bootstrapInvalid) return TenantContext.none;
    if (scenario == FakeIamScenario.contextInvalidated && tenantId == 'org-001') {
      return const TenantContext(
        status: TenantContextStatus.invalidated,
        tenantId: 'org-001',
        tenantName: 'Thú y Minh Phát',
        invalidationReason: TenantContextInvalidationReason.tenantSuspended,
        blockedErrorCode: 'TENANT_SUSPENDED',
      );
    }
    return _contexts[tenantId] ?? TenantContext.none;
  }

  @override
  Future<SessionPrincipal?> getSessionContext(String tenantId) async {
    sessionContextReads++;
    if (failGetSession) {
      throw const AppException(AppErrorCode.unknown);
    }
    final context = _contexts[tenantId];
    if (context == null || context.status != TenantContextStatus.valid) return null;
    final tenant = _tenants.where((item) => item.id == tenantId).firstOrNull;
    return SessionPrincipal(
      userId: 'user-1',
      tenantId: tenantId,
      activeStoreId: 'store-$tenantId',
      role: tenant?.roleCode ?? 'store_owner',
      isOwner: tenant?.isOwner ?? false,
      permissions: context.permissions,
    );
  }

  @override
  Future<List<AccessibleTenant>> listAccessibleTenants({String? currentTenantId}) async {
    if (failNextList) {
      failNextList = false;
      throw const AppException(AppErrorCode.unknown);
    }
    return _tenants
        .map((tenant) => tenant.copyWith(isCurrent: tenant.id == currentTenantId))
        .toList(growable: false);
  }

  @override
  Future<TenantContext> switchTenantContext(String targetTenantId) async {
    if (scenario == FakeIamScenario.switchDenied || switchError != null) {
      throw switchError ?? const AppException('TENANT_ACCESS_DENIED');
    }
    final context = _contexts[targetTenantId];
    if (context == null || context.status != TenantContextStatus.valid) {
      final tenant = _tenants.where((item) => item.id == targetTenantId).firstOrNull;
      if (tenant?.status == TenantStatus.suspended) {
        throw const AppException('TENANT_SUSPENDED');
      }
      if (tenant?.status == TenantStatus.closed) {
        throw const AppException('TENANT_CLOSED');
      }
      throw const AppException('TENANT_ACCESS_DENIED');
    }
    switchCount++;
    return context;
  }

  /// Thành viên không còn trong tổ chức: ngữ cảnh invalidated, biến mất khỏi danh sách.
  void removeMembership(String id) {
    final existing = _contexts[id];
    _contexts[id] = TenantContext(
      status: TenantContextStatus.invalidated,
      tenantId: id,
      tenantName: existing?.tenantName,
      invalidationReason: TenantContextInvalidationReason.membershipRemoved,
    );
    _tenants.removeWhere((tenant) => tenant.id == id);
  }

  void _seed() {
    const minhPhat = _Seed('org-001', 'Thú y Minh Phát', 'Chủ cửa hàng', TenantStatus.active);
    const minhTam = _Seed('org-002', 'Phòng khám Minh Tâm', 'Kế toán', TenantStatus.active);
    const asc = _Seed(
      'org-003',
      'ASC Commerce',
      'Nhân viên bán hàng',
      TenantStatus.suspended,
    );
    const closed = _Seed('org-004', 'Closed Clinic', 'Nhân viên', TenantStatus.closed);
    const provisioning = _Seed(
      'org-005',
      'Vet45 Provisioning',
      'Chủ cửa hàng',
      TenantStatus.provisioning,
      isOwner: true,
    );

    final multi = <_Seed>[minhPhat, minhTam, asc];
    late final List<_Seed> seeds;
    String? current = 'org-001';
    String? last = 'org-001';

    switch (scenario) {
      case _ when noTenants:
        seeds = [];
        current = null;
        last = null;
      case _ when suspendedOnly:
        seeds = [asc];
        current = null;
        last = null;
      case FakeIamScenario.tenantsSingle:
      case FakeIamScenario.tenantsExcludesInactiveMembership:
        seeds = [minhPhat];
      case FakeIamScenario.tenantsProvisioning:
        seeds = [minhPhat, provisioning];
      case FakeIamScenario.switchClosed:
      case FakeIamScenario.tenantsClosedDisabled:
        seeds = [minhPhat, closed];
      case FakeIamScenario.bootstrapInvalid:
        seeds = [minhPhat, minhTam];
        current = null;
        last = 'org-gone';
      case FakeIamScenario.contextNone:
        seeds = [minhPhat, minhTam];
        current = null;
        last = null;
      default:
        seeds = multi;
    }

    lastSelectedTenantId = last;
    for (final seed in seeds) {
      _tenants.add(
        AccessibleTenant(
          id: seed.id,
          name: seed.name,
          code: AccessibleTenant.codeFor(seed.id),
          roleCode: seed.roleCode,
          status: seed.status,
          isOwner: seed.isOwner,
          isCurrent: seed.id == current,
        ),
      );
      if (seed.status == TenantStatus.active ||
          (seed.status == TenantStatus.provisioning && seed.isOwner)) {
        _contexts[seed.id] = TenantContext(
          status: TenantContextStatus.valid,
          tenantId: seed.id,
          tenantName: seed.name,
          roleLabel: seed.roleCode,
          isOwner: seed.isOwner,
          tenantStatus: seed.status,
          permissions: const ['tenant.access'],
        );
      } else if (seed.status == TenantStatus.suspended || seed.status == TenantStatus.closed) {
        final closedTenant = seed.status == TenantStatus.closed;
        _contexts[seed.id] = TenantContext(
          status: TenantContextStatus.invalidated,
          tenantId: seed.id,
          tenantName: seed.name,
          tenantStatus: seed.status,
          invalidationReason: closedTenant
              ? TenantContextInvalidationReason.tenantClosed
              : TenantContextInvalidationReason.tenantSuspended,
          blockedErrorCode: closedTenant ? 'TENANT_CLOSED' : 'TENANT_SUSPENDED',
        );
      }
    }
  }
}

final class _Seed {
  const _Seed(this.id, this.name, this.roleCode, this.status, {this.isOwner = false});

  final String id;
  final String name;
  final String roleCode;
  final TenantStatus status;
  final bool isOwner;
}
