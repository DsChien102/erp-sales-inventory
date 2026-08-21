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
    String? query,
    String? result,
    TenantAuditEventCategory? eventCategory,
    String? subjectType,
    List<String>? eventCodes,
    String? cursor,
    int? limit,
  }) async {
    try {
      final page = await _rpcClient.callMap(
        'search_tenant_audit_logs_v2',
        params: <String, dynamic>{
          'p_tenant_id': tenantId,
          'p_from': from.toUtc().toIso8601String(),
          'p_to': to.toUtc().toIso8601String(),
          'p_query': query,
          'p_result': result,
          'p_event_category': eventCategory?.code,
          'p_subject_type': subjectType,
          'p_event_codes': eventCodes,
          'p_cursor': cursor,
          'p_page_size': limit ?? 20,
        },
      );
      final items = (page['items'] as List? ?? const [])
          .map((e) => _mapSummary((e as Map).cast<String, dynamic>()))
          .toList(growable: false);
      final totalCount = (page['total_count'] as num?)?.toInt() ?? items.length;
      return TenantAuditLogSearchPageDto(
        items: items,
        totalCount: totalCount,
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
      eventCategory: TenantAuditEventCategory.fromCode(
        row['event_category'] as String?,
      ),
      result:
          TenantAuditLogResultCodes.fromCode(row['result'] as String?) ??
          TenantAuditLogResult.success,
      occurredAt: DateTime.parse(row['occurred_at'] as String),
      source: (row['source'] as String?) ?? 'iam',
      trackingId: (row['tracking_id'] as String?) ?? '',
      actor: _mapActor((row['actor'] as Map?)?.cast<String, dynamic>()),
      subject: _mapSubject((row['subject'] as Map?)?.cast<String, dynamic>()),
    );
  }

  TenantAuditLogDetailDto _mapDetail(Map<String, dynamic> row) {
    return TenantAuditLogDetailDto(
      auditLogId: row['audit_log_id'] as String,
      tenantId: row['tenant_id'] as String,
      eventCode: row['event_code'] as String,
      eventCategory: TenantAuditEventCategory.fromCode(
        row['event_category'] as String?,
      ),
      result:
          TenantAuditLogResultCodes.fromCode(row['result'] as String?) ??
          TenantAuditLogResult.success,
      occurredAt: DateTime.parse(row['occurred_at'] as String),
      source: (row['source'] as String?) ?? 'iam',
      trackingId: (row['tracking_id'] as String?) ?? '',
      actorUnavailable: row['actor_unavailable'] as bool? ?? false,
      beforeRedacted: row['before_redacted'] as bool? ?? false,
      afterRedacted: row['after_redacted'] as bool? ?? false,
      actor: _mapActor((row['actor'] as Map?)?.cast<String, dynamic>()),
      subject: _mapSubject((row['subject'] as Map?)?.cast<String, dynamic>()),
      beforeState: _asJsonMap(row['before_state']),
      afterState: _asJsonMap(row['after_state']),
    );
  }

  TenantAuditActorDto _mapActor(Map<String, dynamic>? actorMap) {
    if (actorMap == null) {
      return const TenantAuditActorDto(
        displayOrigin: TenantAuditDisplayOrigin.unavailable,
      );
    }
    return TenantAuditActorDto(
      userId: actorMap['user_id'] as String?,
      displayName: actorMap['display_name'] as String?,
      actorType: actorMap['actor_type'] as String?,
      roleCode: actorMap['role_code'] as String?,
      roleLabel: actorMap['role_label'] as String?,
      displayOrigin: TenantAuditDisplayOrigin.fromCode(
        actorMap['display_origin'] as String?,
      ),
    );
  }

  TenantAuditSubjectDto _mapSubject(Map<String, dynamic>? subjectMap) {
    if (subjectMap == null) {
      return const TenantAuditSubjectDto(
        displayOrigin: TenantAuditDisplayOrigin.unavailable,
      );
    }
    return TenantAuditSubjectDto(
      type: subjectMap['type'] as String?,
      id: subjectMap['id'] as String?,
      displayName: subjectMap['display_name'] as String?,
      code: subjectMap['code'] as String?,
      secondaryLabel: subjectMap['secondary_label'] as String?,
      displayOrigin: TenantAuditDisplayOrigin.fromCode(
        subjectMap['display_origin'] as String?,
      ),
    );
  }

  Map<String, Object?>? _asJsonMap(Object? value) {
    if (value == null) return null;
    return Map<String, Object?>.unmodifiable(
      (value as Map).map((key, item) => MapEntry(key.toString(), item)),
    );
  }
}
