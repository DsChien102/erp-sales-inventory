import '../supabase/supabase_rpc.dart';
import 'models/accessible_tenant.dart';
import 'models/session_principal.dart';
import 'models/tenant_context.dart';

/// RPC phiên (schema `iam`). Không nhận callback tenant — chính nó cung cấp tenant.
class SessionRepository {
  SessionRepository({required SupabaseRpc rpc}) : _rpc = rpc;

  final SupabaseRpc _rpc;

  Future<TenantContext> getTenantContext(String? tenantId) async {
    final result = await _rpc.call(
      'iam',
      'get_tenant_context',
      params: tenantId == null ? null : <String, dynamic>{'p_tenant_id': tenantId},
    );
    final json = _asMap(result);
    if (json.isEmpty) return TenantContext.none;
    return TenantContext.fromJson(json);
  }

  Future<SessionPrincipal?> getSessionContext(String tenantId) async {
    final result = await _rpc.call(
      'iam',
      'get_session_context',
      params: <String, dynamic>{'p_tenant_id': tenantId},
    );
    final json = _asMap(result);
    if (json.isEmpty) return null;
    return SessionPrincipal.fromJson(json);
  }

  Future<List<AccessibleTenant>> listAccessibleTenants({String? currentTenantId}) async {
    final rows = await _rpc.rows('iam', 'list_accessible_tenants');
    return rows
        .map(
          (row) => AccessibleTenant.fromJson(
            row,
            isCurrent: currentTenantId != null && row['tenant_id'] == currentTenantId,
          ),
        )
        .toList(growable: false);
  }

  Future<TenantContext> switchTenantContext(String targetTenantId) async {
    final result = await _rpc.call(
      'iam',
      'switch_tenant_context',
      params: <String, dynamic>{'p_target_tenant_id': targetTenantId},
    );
    return TenantContext.fromJson(_asMap(result));
  }

  /// `iam.has_platform_permission`: chỉ nhận mã bắt đầu `platform.`; người bị
  /// tạm ngừng luôn nhận `false`.
  Future<bool> hasPlatformPermission(String permission) async {
    final result = await _rpc.call(
      'iam',
      'has_platform_permission',
      params: <String, dynamic>{'p_permission': permission},
    );
    return result == true;
  }

  /// `iam.has_permission`: quyền nghiệp vụ của người dùng trong một tổ chức.
  Future<bool> hasPermission(String tenantId, String permission) async {
    final result = await _rpc.call(
      'iam',
      'has_permission',
      params: <String, dynamic>{
        'p_tenant_id': tenantId,
        'p_permission': permission,
      },
    );
    return result == true;
  }

  Future<String?> getLastSelectedTenantId() async {
    final result = await _rpc.call('iam', 'get_last_selected_tenant');
    if (result == null) return null;
    final value = result.toString().trim();
    if (value.isEmpty) return null;
    return value;
  }

  Future<void> setLastSelectedTenantId(String? tenantId) async {
    await _rpc.call(
      'iam',
      'set_last_selected_tenant',
      params: <String, dynamic>{'p_tenant_id': tenantId},
    );
  }
}

Map<String, dynamic> _asMap(dynamic result) {
  if (result == null) return const {};
  if (result is Map) return Map<String, dynamic>.from(result);
  if (result is List && result.isNotEmpty && result.first is Map) {
    return Map<String, dynamic>.from(result.first as Map);
  }
  return const {};
}
