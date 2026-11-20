import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';

import 'iam_json.dart';
import 'models/tenant_audit_log.dart';

class AuditLogRepository {
  AuditLogRepository({required SupabaseRpc rpc, required Future<String> Function() tenantId})
    : _rpc = rpc,
      _tenantId = tenantId;

  final SupabaseRpc _rpc;
  final Future<String> Function() _tenantId;

  /// Gateway cũ gọi `search_tenant_audit_logs_v2` (10 tham số, gồm `p_event_codes`).
  /// Hàm 9 tham số `search_tenant_audit_logs` đã bị migration `20260826004` xoá.
  Future<TenantAuditLogPage> search({
    required DateTime from,
    required DateTime to,
    String? query,
    String? result,
    String? eventCategory,
    String? subjectType,
    List<String>? eventCodes,
    String? cursor,
    int limit = 20,
  }) async {
    if (!from.isBefore(to)) {
      throw const AppException(AppErrorCode.validation);
    }
    if (limit < 1 || limit > 100) {
      throw const AppException(AppErrorCode.validation);
    }
    final page = iamJsonMap(
      await _rpc.call(
        'iam',
        'search_tenant_audit_logs_v2',
        params: {
          'p_tenant_id': await _tenantId(),
          'p_from': from.toUtc().toIso8601String(),
          'p_to': to.toUtc().toIso8601String(),
          'p_query': query,
          'p_result': result,
          'p_event_category': eventCategory,
          'p_subject_type': subjectType,
          'p_event_codes': eventCodes,
          'p_cursor': cursor,
          'p_page_size': limit,
        },
      ),
    );
    return TenantAuditLogPage.fromJson(page);
  }

  Future<TenantAuditLogDetail> getDetail(String auditLogId) async {
    final row = iamJsonMap(
      await _rpc.call(
        'iam',
        'get_tenant_audit_log',
        params: {'p_tenant_id': await _tenantId(), 'p_audit_log_id': auditLogId},
      ),
    );
    if (row.isEmpty) throw const AppException(AppErrorCode.notFound);
    return TenantAuditLogDetail.fromJson(row);
  }
}
