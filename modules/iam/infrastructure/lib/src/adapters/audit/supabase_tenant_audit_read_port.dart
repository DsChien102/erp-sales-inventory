import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/iam_blocked_error_mapper.dart';

/// Real tenant-scoped audit read adapter over `iam.audit_logs` (§S13).
final class SupabaseTenantAuditReadPort implements ITenantAuditReadPort {
  SupabaseTenantAuditReadPort({required SupabaseSchemaRpcClient rpcClient})
    : _rpcClient = rpcClient;

  final SupabaseSchemaRpcClient _rpcClient;

  @override
  Future<TenantAuditLogSearchPageDto> search({
    required String tenantId,
    required DateTime from,
    required DateTime to,
    String? result,
    String? actorUserId,
    String? subjectType,
    String? eventCode,
    String? cursor,
    int? limit,
  }) async {
    try {
      final page = await _rpcClient.callMap(
        'search_tenant_audit_logs',
        params: <String, dynamic>{
          'p_tenant_id': tenantId,
          'p_from': from.toUtc().toIso8601String(),
          'p_to': to.toUtc().toIso8601String(),
          'p_result': result,
          'p_actor_query': actorUserId,
          'p_subject_type': subjectType,
          'p_event_code': eventCode,
          'p_cursor': cursor,
          'p_page_size': limit ?? 20,
        },
      );
      final items = (page['items'] as List? ?? const [])
          .map((e) => _mapSummary((e as Map).cast<String, dynamic>()))
          .toList(growable: false);
      return TenantAuditLogSearchPageDto(
        items: items,
        nextCursor: page['next_cursor'] as String?,
      );
    } on RpcException catch (error) {
      throw mapIamBlockedRpcError(error);
    }
  }

  @override
  Future<TenantAuditLogDetailDto?> getDetail({
    required String tenantId,
    required String auditLogId,
  }) async {
    try {
      final row = await _rpcClient.callMap(
        'get_tenant_audit_log',
        params: <String, dynamic>{
          'p_tenant_id': tenantId,
          'p_audit_log_id': auditLogId,
        },
      );
      if (row.isEmpty) {
        return null;
      }
      return _mapDetail(row);
    } on RpcException catch (error) {
      final mapped = mapIamBlockedRpcError(error);
      // Non-enumerating: cross-tenant / missing resolves to "not found" (null).
      if (error.message.toUpperCase().contains('RESOURCE_NOT_FOUND') ||
          mapped.code == IamBlockedCodes.resourceNotFound) {
        return null;
      }
      throw mapped;
    }
  }

  TenantAuditLogSummaryDto _mapSummary(Map<String, dynamic> row) {
    return TenantAuditLogSummaryDto(
      auditLogId: row['audit_log_id'] as String,
      eventCode: row['event_code'] as String,
      result:
          TenantAuditLogResultCodes.fromCode(row['result'] as String?) ??
          TenantAuditLogResult.success,
      occurredAt: DateTime.parse(row['occurred_at'] as String),
      source: (row['source'] as String?) ?? 'iam',
      trackingId: (row['tracking_id'] as String?) ?? '',
      actorUserId: row['actor_user_id'] as String?,
      actorDisplayName: row['actor_display_name'] as String?,
      subjectType: row['subject_type'] as String?,
      subjectId: row['subject_id'] as String?,
    );
  }

  TenantAuditLogDetailDto _mapDetail(Map<String, dynamic> row) {
    return TenantAuditLogDetailDto(
      auditLogId: row['audit_log_id'] as String,
      tenantId: row['tenant_id'] as String,
      eventCode: row['event_code'] as String,
      result:
          TenantAuditLogResultCodes.fromCode(row['result'] as String?) ??
          TenantAuditLogResult.success,
      occurredAt: DateTime.parse(row['occurred_at'] as String),
      source: (row['source'] as String?) ?? 'iam',
      trackingId: (row['tracking_id'] as String?) ?? '',
      actorUnavailable: row['actor_unavailable'] as bool? ?? false,
      beforeRedacted: row['before_redacted'] as bool? ?? false,
      afterRedacted: row['after_redacted'] as bool? ?? false,
      actorUserId: row['actor_user_id'] as String?,
      actorDisplayName: row['actor_display_name'] as String?,
      subjectType: row['subject_type'] as String?,
      subjectId: row['subject_id'] as String?,
      beforeState: _asJsonText(row['before_state']),
      afterState: _asJsonText(row['after_state']),
    );
  }

  String? _asJsonText(Object? value) {
    if (value == null) return null;
    return value.toString();
  }
}
