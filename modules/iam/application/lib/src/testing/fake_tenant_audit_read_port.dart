import '../ports/i_tenant_audit_read_port.dart';
import '../shared/iam_blocked_codes.dart';
import '../shared/iam_blocked_exception.dart';
import '../tenant/shared/tenant_audit_actor_dto.dart';
import '../tenant/shared/tenant_audit_display_origin.dart';
import '../tenant/shared/tenant_audit_event_category.dart';
import '../tenant/shared/tenant_audit_log_detail_dto.dart';
import '../tenant/shared/tenant_audit_log_result.dart';
import '../tenant/shared/tenant_audit_log_search_page_dto.dart';
import '../tenant/shared/tenant_audit_log_summary_dto.dart';
import '../tenant/shared/tenant_audit_subject_dto.dart';
import 'fake_iam_scenario.dart';

/// In-memory tenant audit read port for tests (§S13).
final class FakeTenantAuditReadPort implements ITenantAuditReadPort {
  FakeTenantAuditReadPort({
    this.scenario = FakeIamScenario.tenantAuditSearchOk,
    List<TenantAuditLogSummaryDto>? summaries,
    TenantAuditLogDetailDto? detail,
  }) : _summaries =
           summaries ??
           [
             TenantAuditLogSummaryDto(
               auditLogId: 'AUD-T-001',
               eventCode: 'iam.tenant.profile.updated',
               result: TenantAuditLogResult.success,
               occurredAt: DateTime.utc(2026, 7, 13, 8),
               source: 'tenant-app',
               trackingId: 'TRK-001',
               actor: const TenantAuditActorDto(
                 userId: 'lan-le',
                 displayName: 'Lê Thị Lan',
                 actorType: 'user',
                 roleCode: 'store_owner',
                 roleLabel: 'Chủ sở hữu',
                 displayOrigin: TenantAuditDisplayOrigin.snapshot,
               ),
               subject: const TenantAuditSubjectDto(
                 type: 'tenant',
                 id: 'org-001',
                 displayName: 'Chi nhánh Quận 1',
                 code: 'CN-Q1',
                 secondaryLabel: null,
                 displayOrigin: TenantAuditDisplayOrigin.snapshot,
               ),
             ),
           ],
       _detail =
           detail ??
           TenantAuditLogDetailDto(
             auditLogId: 'AUD-T-001',
             tenantId: 'org-001',
             eventCode: 'iam.tenant.profile.updated',
             result: TenantAuditLogResult.success,
             occurredAt: DateTime.utc(2026, 7, 13, 8),
             source: 'tenant-app',
             trackingId: 'TRK-001',
             actorUnavailable: false,
             beforeRedacted: false,
             afterRedacted: false,
             actor: const TenantAuditActorDto(
               userId: 'lan-le',
               displayName: 'Lê Thị Lan',
               actorType: 'user',
               roleCode: 'store_owner',
               roleLabel: 'Chủ sở hữu',
               displayOrigin: TenantAuditDisplayOrigin.snapshot,
             ),
             subject: const TenantAuditSubjectDto(
               type: 'tenant',
               id: 'org-001',
               displayName: 'Chi nhánh Quận 1',
               code: 'CN-Q1',
               secondaryLabel: null,
               displayOrigin: TenantAuditDisplayOrigin.snapshot,
             ),
             beforeState: const {'display_name': 'Old'},
             afterState: const {'display_name': 'New'},
           );

  final FakeIamScenario scenario;
  final List<TenantAuditLogSummaryDto> _summaries;
  final TenantAuditLogDetailDto _detail;

  @override
  Future<TenantAuditLogDetailDto?> getDetail({
    required String tenantId,
    required String auditLogId,
  }) async {
    if (scenario == FakeIamScenario.tenantAuditProviderError) {
      throw const IamBlockedException(IamBlockedCodes.systemError);
    }
    if (scenario == FakeIamScenario.tenantAuditActorUnavailable) {
      return TenantAuditLogDetailDto(
        auditLogId: auditLogId,
        tenantId: tenantId,
        eventCode: _detail.eventCode,
        result: _detail.result,
        occurredAt: _detail.occurredAt,
        source: _detail.source,
        trackingId: _detail.trackingId,
        actorUnavailable: true,
        beforeRedacted: _detail.beforeRedacted,
        afterRedacted: _detail.afterRedacted,
        actor: const TenantAuditActorDto(
          userId: 'lan-le',
          displayName: null,
          actorType: 'user',
          roleCode: null,
          roleLabel: null,
          displayOrigin: TenantAuditDisplayOrigin.unavailable,
        ),
        subject: _detail.subject,
        beforeState: _detail.beforeState,
        afterState: _detail.afterState,
      );
    }
    if (scenario == FakeIamScenario.tenantAuditCrossTenant) {
      return null;
    }
    if (auditLogId != _detail.auditLogId || tenantId != _detail.tenantId) {
      return null;
    }
    return _detail;
  }

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
    if (scenario == FakeIamScenario.tenantAuditProviderError) {
      throw const IamBlockedException(IamBlockedCodes.systemError);
    }
    if (scenario == FakeIamScenario.tenantAuditEmpty) {
      return const TenantAuditLogSearchPageDto(items: [], totalCount: 0);
    }
    if (scenario == FakeIamScenario.tenantAuditCrossTenant) {
      return const TenantAuditLogSearchPageDto(items: [], totalCount: 0);
    }
    var filtered = _summaries.where((s) => s.subject.id == tenantId || tenantId == 'org-001');
    if (eventCodes != null && eventCodes.isNotEmpty) {
      filtered = filtered.where((s) => eventCodes.contains(s.eventCode));
    }
    if (result != null) {
      filtered = filtered.where((s) => s.result.code == result);
    }
    if (subjectType != null) {
      filtered = filtered.where((s) => s.subject.type == subjectType);
    }
    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      filtered = filtered.where(
        (s) =>
            (s.actor.displayName?.toLowerCase().contains(q) ?? false) ||
            (s.subject.displayName?.toLowerCase().contains(q) ?? false) ||
            s.eventCode.toLowerCase().contains(q) ||
            s.auditLogId.toLowerCase().contains(q) ||
            s.trackingId.toLowerCase().contains(q) ||
            (s.actor.userId?.toLowerCase() == q) ||
            (s.subject.id?.toLowerCase() == q),
      );
    }
    final list = filtered.toList();
    return TenantAuditLogSearchPageDto(items: list, totalCount: list.length);
  }
}
