import 'package:uuid/uuid.dart';
import 'package:vet45_shared_application/application.dart';

import 'session_repository.dart';
import 'session_store.dart';

/// Ngữ cảnh thực thi cho các module nghiệp vụ cũ, đọc từ [SessionStore].
///
/// Giữ nguyên chuỗi lỗi (`User is required`, `Tenant is required`): các mapper
/// của module cũ so khớp theo chuỗi.
final class CoreExecutionContext implements IExecutionContext, ICurrentUser, ICurrentTenant {
  CoreExecutionContext({required SessionStore store, String? correlationId})
    : _store = store,
      correlationId = correlationId ?? const Uuid().v4();

  final SessionStore _store;

  @override
  final String correlationId;

  @override
  String? get userId => _store.userId;

  @override
  String? get tenantId => _store.tenantId;

  @override
  Future<String> requireUserId() async {
    final userId = _store.userId;
    if (userId == null) {
      throw const ApplicationException('User is required');
    }
    return userId;
  }

  @override
  Future<String> requireTenantId() async {
    final tenantId = _store.tenantId;
    if (tenantId == null) {
      throw const ApplicationException('Tenant is required');
    }
    return tenantId;
  }
}

/// Kiểm tra quyền cho pipeline lệnh của module nghiệp vụ.
///
/// - `platform.*`: RPC `has_platform_permission` (không cần tổ chức).
/// - Chủ sở hữu, hoặc phiên đã có quyền: qua, không gọi mạng.
/// - Còn lại: RPC `iam.has_permission(p_tenant_id, p_permission)`.
final class CorePermissionChecker implements IPermissionChecker {
  CorePermissionChecker({
    required SessionStore store,
    required SessionRepository repository,
    required IExecutionContext executionContext,
  }) : _store = store,
       _repository = repository,
       _executionContext = executionContext;

  final SessionStore _store;
  final SessionRepository _repository;
  final IExecutionContext _executionContext;

  @override
  Future<void> require(String permissionCode) async {
    if (permissionCode.startsWith('platform.')) {
      final allowed = await _repository.hasPlatformPermission(permissionCode);
      if (!allowed) throw _denied(permissionCode);
      return;
    }

    if (_store.isOwner || _store.hasPermission(permissionCode)) {
      return;
    }

    final tenantId = await _executionContext.requireTenantId();
    final allowed = await _repository.hasPermission(tenantId, permissionCode);
    if (!allowed) throw _denied(permissionCode);
  }

  static ApplicationException _denied(String permissionCode) {
    return ApplicationException('Permission denied: $permissionCode');
  }
}

/// Người dùng hiện tại phải là thành viên của tổ chức được yêu cầu.
final class CoreTenantAccessChecker implements ITenantAccessChecker {
  CoreTenantAccessChecker({required SessionRepository repository}) : _repository = repository;

  final SessionRepository _repository;

  @override
  Future<void> ensureAccess(String tenantId) async {
    final principal = await _repository.getSessionContext(tenantId);
    if (principal == null) {
      throw ApplicationException('Tenant access denied: $tenantId');
    }
  }
}
