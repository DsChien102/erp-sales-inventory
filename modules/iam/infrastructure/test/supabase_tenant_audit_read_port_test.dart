import 'package:test/test.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_infrastructure/src/adapters/audit/supabase_tenant_audit_read_port.dart';

import 'support/fake_iam_rpc_supabase.dart';

void main() {
  group('SupabaseTenantAuditReadPort', () {
    late FakeIamRpcSupabase supabase;
    late SupabaseTenantAuditReadPort port;

    setUp(() {
      supabase = FakeIamRpcSupabase();
      port = SupabaseTenantAuditReadPort(
        rpcClient: SupabaseSchemaRpcClient(
          supabase: supabase,
          schema: 'iam',
          mapError: (e, [st]) => e,
        ),
      );
    });

    test(
      'search passes exact V2 parameters and maps nested actor/subject and totalCount',
      () async {
        supabase.registerHandler('search_tenant_audit_logs_v2', (params) async {
          return {
            'items': [
              {
                'audit_log_id': 'aud-001',
                'event_code': 'iam.tenant.activated',
                'result': 'success',
                'occurred_at': '2026-08-20T10:00:00.000Z',
                'source': 'iam',
                'tracking_id': 'trk-001',
                'actor': {
                  'user_id': 'user-001',
                  'display_name': 'Nguyễn Văn A',
                  'actor_type': 'user',
                  'role_code': 'store_owner',
                  'role_label': 'Chủ sở hữu',
                  'display_origin': 'snapshot',
                },
                'subject': {
                  'type': 'tenant',
                  'id': 'tenant-001',
                  'display_name': 'Phòng khám Vet 45',
                  'code': 'VET45-HCM',
                  'secondary_label': null,
                  'display_origin': 'snapshot',
                },
              },
            ],
            'total_count': 42,
            'next_cursor': 'cursor-next',
          };
        });

        final from = DateTime.utc(2026, 8, 1);
        final to = DateTime.utc(2026, 8, 31);
        final result = await port.search(
          tenantId: 'tenant-001',
          from: from,
          to: to,
          query: 'Nguyễn Văn A',
          result: 'success',
          eventCategory: TenantAuditEventCategory.organization,
          subjectType: 'tenant',
          eventCodes: ['iam.tenant.activated'],
          cursor: 'cursor-prev',
          limit: 25,
        );

        expect(supabase.calls.length, 1);
        final call = supabase.calls.first;
        expect(call.functionName, 'search_tenant_audit_logs_v2');
        expect(call.params?['p_tenant_id'], 'tenant-001');
        expect(call.params?['p_from'], from.toIso8601String());
        expect(call.params?['p_to'], to.toIso8601String());
        expect(call.params?['p_query'], 'Nguyễn Văn A');
        expect(call.params?['p_result'], 'success');
        expect(call.params?['p_event_category'], 'organization');
        expect(call.params?['p_subject_type'], 'tenant');
        expect(call.params?['p_event_codes'], ['iam.tenant.activated']);
        expect(call.params?['p_cursor'], 'cursor-prev');
        expect(call.params?['p_page_size'], 25);

        expect(result.totalCount, 42);
        expect(result.nextCursor, 'cursor-next');
        expect(result.items.length, 1);
        final item = result.items.first;
        expect(item.auditLogId, 'aud-001');
        expect(item.actor.displayName, 'Nguyễn Văn A');
        expect(item.actor.roleCode, 'store_owner');
        expect(item.actor.roleLabel, 'Chủ sở hữu');
        expect(item.actor.displayOrigin, TenantAuditDisplayOrigin.snapshot);
        expect(item.subject.displayName, 'Phòng khám Vet 45');
        expect(item.subject.code, 'VET45-HCM');
        expect(item.subject.displayOrigin, TenantAuditDisplayOrigin.snapshot);
      },
    );

    test('getDetail maps nested actor/subject and typed before/after JSON states', () async {
      supabase.registerHandler('get_tenant_audit_log', (params) async {
        return {
          'audit_log_id': 'aud-001',
          'audit_display_id': 'AUD-000982',
          'tenant_id': 'tenant-001',
          'activity_code': 'iam.tenant.activated',
          'event_code': 'iam.tenant.activated',
          'title_snapshot': 'Đã kích hoạt tổ chức',
          'result': 'success',
          'occurred_at': '2026-08-20T10:00:00.000Z',
          'source': 'iam',
          'correlation_id': 'corr-001',
          'tracking_id': 'trk-001',
          'actor_unavailable': false,
          'before_redacted': false,
          'after_redacted': false,
          'actor': {
            'user_id': 'user-001',
            'display_name': 'Nguyễn Văn A',
            'actor_type': 'user',
            'role_code': 'store_owner',
            'role_label': 'Chủ sở hữu',
            'display_origin': 'snapshot',
          },
          'subject': {
            'type': 'tenant',
            'id': 'tenant-001',
            'display_name': 'Phòng khám Vet 45',
            'code': 'VET45-HCM',
            'secondary_label': null,
            'display_origin': 'snapshot',
          },
          'before_state': {'status': 'provisioning', 'version': 1},
          'after_state': {'status': 'active', 'version': 2},
        };
      });

      final detail = await port.getDetail(
        tenantId: 'tenant-001',
        auditLogId: 'aud-001',
      );

      expect(supabase.calls.length, 1);
      final call = supabase.calls.first;
      expect(call.functionName, 'get_tenant_audit_log');
      expect(call.params?['p_tenant_id'], 'tenant-001');
      expect(call.params?['p_audit_log_id'], 'aud-001');

      expect(detail, isNotNull);
      expect(detail!.auditLogId, 'aud-001');
      expect(detail.auditDisplayId, 'AUD-000982');
      expect(detail.activityCode, 'iam.tenant.activated');
      expect(detail.titleSnapshot, 'Đã kích hoạt tổ chức');
      expect(detail.correlationId, 'corr-001');
      expect(detail.actor.displayName, 'Nguyễn Văn A');
      expect(detail.actor.displayOrigin, TenantAuditDisplayOrigin.snapshot);
      expect(detail.subject.code, 'VET45-HCM');
      expect(detail.beforeState?['status'], 'provisioning');
      expect(detail.beforeState?['version'], 1);
      expect(detail.afterState?['status'], 'active');
      expect(detail.afterState?['version'], 2);
    });
  });
}
