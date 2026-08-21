import 'package:test/test.dart';
import 'package:vet45_iam_application/testing.dart';

final class _RecordingTenantAuditReadPort implements ITenantAuditReadPort {
  DateTime? receivedFrom;
  DateTime? receivedTo;

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
    receivedFrom = from;
    receivedTo = to;
    return const TenantAuditLogSearchPageDto(items: [], totalCount: 0);
  }

  @override
  Future<TenantAuditLogDetailDto?> getDetail({
    required String tenantId,
    required String auditLogId,
  }) async {
    return null;
  }
}

void main() {
  final port = FakeTenantAuditReadPort(
    scenario: FakeIamScenario.tenantAuditSearchOk,
  );

  group('scn_e02_u07 tenant audit handlers', () {
    test('SearchTenantAuditLogsQuery returns summaries', () async {
      final handler = SearchTenantAuditLogsQueryHandler(auditReadPort: port);
      final result = await handler.handle(
        SearchTenantAuditLogsQuery(
          tenantId: 'org-001',
          fromUtc: DateTime.utc(2026, 7, 1),
          toUtc: DateTime.utc(2026, 7, 31),
        ),
      );
      expect(result.items, isNotEmpty);
    });

    test('SearchTenantAuditLogsQuery rejects invalid time range', () async {
      final handler = SearchTenantAuditLogsQueryHandler(auditReadPort: port);
      expect(
        () => handler.handle(
          SearchTenantAuditLogsQuery(
            tenantId: 'org-001',
            fromUtc: DateTime.utc(2026, 8, 1),
            toUtc: DateTime.utc(2026, 7, 1),
          ),
        ),
        throwsA(
          isA<IamBlockedException>().having(
            (e) => e.code,
            'code',
            IamBlockedCodes.validationError,
          ),
        ),
      );
    });

    test('GetTenantAuditLogQuery returns detail', () async {
      final handler = GetTenantAuditLogQueryHandler(auditReadPort: port);
      final result = await handler.handle(
        GetTenantAuditLogQuery(
          tenantId: 'org-001',
          auditLogId: 'AUD-T-001',
        ),
      );
      expect(result.auditLogId, 'AUD-T-001');
    });

    test('GetTenantAuditLogQuery throws RESOURCE_NOT_FOUND', () async {
      final handler = GetTenantAuditLogQueryHandler(auditReadPort: port);
      expect(
        () => handler.handle(
          GetTenantAuditLogQuery(
            tenantId: 'org-001',
            auditLogId: 'missing',
          ),
        ),
        throwsA(
          isA<IamBlockedException>().having(
            (e) => e.code,
            'code',
            IamBlockedCodes.resourceNotFound,
          ),
        ),
      );
    });

    test('search filters by eventCodes', () async {
      final handler = SearchTenantAuditLogsQueryHandler(auditReadPort: port);
      final matched = await handler.handle(
        SearchTenantAuditLogsQuery(
          tenantId: 'org-001',
          fromUtc: DateTime.utc(2026, 7, 1),
          toUtc: DateTime.utc(2026, 7, 31),
          eventCodes: const ['iam.tenant.profile.updated'],
        ),
      );
      expect(matched.items, isNotEmpty);

      final missed = await handler.handle(
        SearchTenantAuditLogsQuery(
          tenantId: 'org-001',
          fromUtc: DateTime.utc(2026, 7, 1),
          toUtc: DateTime.utc(2026, 7, 31),
          eventCodes: const ['iam.unknown.event'],
        ),
      );
      expect(missed.items, isEmpty);
    });

    test('detail never exposes secret material in before/after state', () async {
      final handler = GetTenantAuditLogQueryHandler(auditReadPort: port);
      final result = await handler.handle(
        GetTenantAuditLogQuery(
          tenantId: 'org-001',
          auditLogId: 'AUD-T-001',
        ),
      );
      final blob = '${result.beforeState ?? ''}${result.afterState ?? ''}${result.trackingId}';
      expect(blob.toLowerCase(), isNot(contains('password')));
      expect(blob.toLowerCase(), isNot(contains('otp')));
      expect(blob.toLowerCase(), isNot(contains('token')));
    });

    test('provider error surfaces SYSTEM_ERROR', () async {
      final failing = FakeTenantAuditReadPort(
        scenario: FakeIamScenario.tenantAuditProviderError,
      );
      final handler = SearchTenantAuditLogsQueryHandler(auditReadPort: failing);
      expect(
        () => handler.handle(
          SearchTenantAuditLogsQuery(
            tenantId: 'org-001',
            fromUtc: DateTime.utc(2026, 7, 1),
            toUtc: DateTime.utc(2026, 7, 31),
          ),
        ),
        throwsA(
          isA<IamBlockedException>().having(
            (e) => e.code,
            'code',
            IamBlockedCodes.systemError,
          ),
        ),
      );
    });

    test('forwards exact UTC endpoints to the port unchanged', () async {
      final recordingPort = _RecordingTenantAuditReadPort();
      final handler = SearchTenantAuditLogsQueryHandler(
        auditReadPort: recordingPort,
      );
      final fromUtc = DateTime.utc(2026, 7, 1, 2, 3, 4, 5, 6);
      final toUtc = DateTime.utc(2026, 7, 30, 20, 10, 9, 8, 7);

      await handler.handle(
        SearchTenantAuditLogsQuery(
          tenantId: 'org-001',
          fromUtc: fromUtc,
          toUtc: toUtc,
        ),
      );

      expect(recordingPort.receivedFrom, fromUtc);
      expect(recordingPort.receivedTo, toUtc);
    });
  });
}
