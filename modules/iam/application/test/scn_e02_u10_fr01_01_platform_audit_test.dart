import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';

import 'support/stub_platform_admin_gateway.dart';

final class _AuditGateway extends StubPlatformAdminGateway {
  String? lastAction;
  String? lastResult;

  @override
  Future<CursorPageDto<PlatformAuditLogSummaryDto>> searchPlatformAuditLogs({
    DateTime? fromUtc,
    DateTime? toUtc,
    String? actorUserId,
    String? targetType,
    String? targetId,
    String? action,
    String? result,
    String? source,
    String? correlationId,
    String? cursor,
    int limit = 20,
  }) async {
    lastAction = action;
    lastResult = result;
    return CursorPageDto(
      items: [
        PlatformAuditLogSummaryDto(
          id: 'a-1',
          title: 'Suspend',
          actionCode: 'iam.tenant.suspended',
          status: PlatformAuditLogStatus.success,
          actorName: 'Admin',
          actorRole: 'ops',
          targetOrgName: 'Store',
          targetOrgCode: 'TEN-1',
          timestamp: DateTime.utc(2026, 7, 1),
          sourceApp: 'admin',
        ),
      ],
    );
  }

  @override
  Future<PlatformAuditLogDetailDto> getPlatformAuditLog(
    String auditLogId,
  ) async {
    return PlatformAuditLogDetailDto(
      id: auditLogId,
      title: 'Suspend',
      actionCode: 'iam.tenant.suspended',
      status: PlatformAuditLogStatus.success,
      statusLabel: 'success',
      actorName: 'Admin',
      actorRole: 'ops',
      targetOrgName: 'Store',
      targetOrgCode: 'TEN-1',
      timestamp: DateTime.utc(2026, 7, 1),
      sourceApp: 'admin',
      correlationId: 'corr-1',
      beforeState: '{}',
      afterState: '{}',
    );
  }
}

void main() {
  group('scn_e02_u10 platform audit', () {
    test('audit_search_ok returns cursor page', () async {
      final gateway = _AuditGateway();
      final page = await SearchPlatformAuditLogsQueryHandler(
        platformGateway: gateway,
      ).handle(
        SearchPlatformAuditLogsQuery(
          action: 'iam.tenant.suspended',
          result: 'success',
        ),
      );
      expect(gateway.lastAction, 'iam.tenant.suspended');
      expect(gateway.lastResult, 'success');
      expect(page.items, hasLength(1));
    });

    test('get detail ok', () async {
      final detail = await GetPlatformAuditLogQueryHandler(
        platformGateway: _AuditGateway(),
      ).handle(GetPlatformAuditLogQuery(auditLogId: 'a-1'));
      expect(detail.correlationId, 'corr-1');
    });
  });
}
