import '../tenant/shared/tenant_audit_log_detail_dto.dart';
import '../tenant/shared/tenant_audit_log_result.dart';
import '../tenant/shared/tenant_audit_log_search_page_dto.dart';
import '../tenant/shared/tenant_audit_log_summary_dto.dart';
import '../ports/i_tenant_audit_read_port.dart';
import '../shared/iam_blocked_codes.dart';
import '../shared/iam_blocked_exception.dart';
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
               actorUserId: 'lan-le',
               actorDisplayName: 'Lê Thị Lan',
               subjectType: 'tenant',
               subjectId: 'org-001',
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
             actorUserId: 'lan-le',
             actorDisplayName: 'Lê Thị Lan',
             subjectType: 'tenant',
             subjectId: 'org-001',
             beforeState: 'display_name: Old',
             afterState: 'display_name: New',
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
        subjectType: _detail.subjectType,
        subjectId: _detail.subjectId,
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
    String? result,
    String? actorUserId,
    String? subjectType,
    String? eventCode,
    String? cursor,
    int? limit,
  }) async {
    if (scenario == FakeIamScenario.tenantAuditProviderError) {
      throw const IamBlockedException(IamBlockedCodes.systemError);
    }
    if (scenario == FakeIamScenario.tenantAuditEmpty) {
      return const TenantAuditLogSearchPageDto(items: []);
    }
    if (scenario == FakeIamScenario.tenantAuditCrossTenant) {
      return const TenantAuditLogSearchPageDto(items: []);
    }
    var filtered = _summaries
        .where((s) => s.subjectId == tenantId || tenantId == 'org-001');
    if (eventCode != null) {
      filtered = filtered.where((s) => s.eventCode == eventCode);
    }
    if (result != null) {
      filtered = filtered.where((s) => s.result.code == result);
    }
    if (subjectType != null) {
      filtered = filtered.where((s) => s.subjectType == subjectType);
    }
    if (actorUserId != null) {
      filtered = filtered.where((s) => s.actorUserId == actorUserId);
    }
    return TenantAuditLogSearchPageDto(items: filtered.toList());
  }
}
