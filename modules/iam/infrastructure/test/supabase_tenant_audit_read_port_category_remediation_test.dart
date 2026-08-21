import 'package:test/test.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_infrastructure/src/adapters/audit/supabase_tenant_audit_read_port.dart';

import 'support/fake_iam_rpc_supabase.dart';

void main() {
  test('read port maps nullable event_category on summary and detail', () async {
    final supabase = FakeIamRpcSupabase()
      ..registerHandler('search_tenant_audit_logs_v2', (_) async {
        return {
          'items': [
            {
              'audit_log_id': 'audit-summary',
              'event_code': IamAuditEvents.tenantActivated,
              'event_category': 'security',
              'result': 'success',
              'occurred_at': '2026-08-20T10:00:00.000Z',
              'actor': <String, Object?>{},
              'subject': <String, Object?>{},
            },
          ],
          'total_count': 1,
        };
      })
      ..registerHandler('get_tenant_audit_log', (_) async {
        return {
          'audit_log_id': 'audit-detail',
          'tenant_id': 'tenant-1',
          'event_code': IamAuditEvents.tenantActivated,
          'event_category': 'account',
          'result': 'success',
          'occurred_at': '2026-08-20T10:00:00.000Z',
          'actor': <String, Object?>{},
          'subject': <String, Object?>{},
        };
      });
    final port = SupabaseTenantAuditReadPort(
      rpcClient: SupabaseSchemaRpcClient(
        supabase: supabase,
        schema: 'iam',
        mapError: (error, [stackTrace]) => error,
      ),
    );

    final page = await port.search(
      tenantId: 'tenant-1',
      from: DateTime.utc(2026, 8, 1),
      to: DateTime.utc(2026, 9, 1),
    );
    final detail = await port.getDetail(
      tenantId: 'tenant-1',
      auditLogId: 'audit-detail',
    );

    expect(page.items.single.eventCategory, TenantAuditEventCategory.security);
    expect(detail?.eventCategory, TenantAuditEventCategory.account);
  });
}
