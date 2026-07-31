import 'package:test/test.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_iam_infrastructure/src/domain/access/supabase_iam_access_gateway.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'support/fake_iam_rpc_supabase.dart';

void main() {
  group('SupabaseIamAccessGateway.listTenantMembers', () {
    test('sends exact RPC name and all params', () async {
      final supabase = FakeIamRpcSupabase()
        ..registerHandler(
          'list_tenant_members',
          (_) async => {
            'items': <Map<String, dynamic>>[],
            'next_cursor': null,
          },
        );
      final gateway = _gateway(supabase);

      await gateway.listTenantMembers(
        tenantId: 'tenant-1',
        search: 'an',
        status: 'inactive',
        cursor: 'opaque',
        limit: 25,
      );

      expect(supabase.calls, hasLength(1));
      expect(supabase.calls.single.functionName, 'list_tenant_members');
      expect(supabase.calls.single.params, {
        'p_tenant_id': 'tenant-1',
        'p_search': 'an',
        'p_status': 'inactive',
        'p_cursor': 'opaque',
        'p_limit': 25,
      });
    });

    test('maps every TenantMemberDto field and next_cursor', () async {
      final supabase = FakeIamRpcSupabase()
        ..registerHandler(
          'list_tenant_members',
          (_) async => {
            'items': [
              {
                'membership_id': 'mem-1',
                'user_id': 'user-1',
                'display_name': 'Nguyen Van An',
                'email': 'an@example.com',
                'role_id': 'role-staff',
                'role_label': 'Nhan vien',
                'is_owner': false,
                'status': 'inactive',
                'joined_at': '2026-07-01T00:00:00Z',
                'version': 3,
              },
            ],
            'next_cursor': 'opaque-next',
          },
        );
      final gateway = _gateway(supabase);

      final page = await gateway.listTenantMembers(
        tenantId: 'tenant-1',
        limit: 20,
      );

      expect(page.nextCursor, 'opaque-next');
      expect(page.items, hasLength(1));
      final item = page.items.single;
      expect(item.membershipId, 'mem-1');
      expect(item.userId, 'user-1');
      expect(item.displayName, 'Nguyen Van An');
      expect(item.email, 'an@example.com');
      expect(item.roleId, 'role-staff');
      expect(item.roleLabel, 'Nhan vien');
      expect(item.isOwner, isFalse);
      expect(item.status, 'inactive');
      expect(item.joinedAt.toUtc().toIso8601String(), '2026-07-01T00:00:00.000Z');
      expect(item.version, 3);
    });

    test('omits nullable search/status/cursor params', () async {
      final supabase = FakeIamRpcSupabase()
        ..registerHandler(
          'list_tenant_members',
          (_) async => {
            'items': <Map<String, dynamic>>[],
            'next_cursor': null,
          },
        );
      final gateway = _gateway(supabase);

      await gateway.listTenantMembers(tenantId: 'tenant-1', limit: 10);

      expect(supabase.calls.single.params, {
        'p_tenant_id': 'tenant-1',
        'p_limit': 10,
      });
      expect(supabase.calls.single.params!.containsKey('p_search'), isFalse);
      expect(supabase.calls.single.params!.containsKey('p_status'), isFalse);
      expect(supabase.calls.single.params!.containsKey('p_cursor'), isFalse);
    });

    test('maps PERMISSION_DENIED stably', () async {
      final supabase = FakeIamRpcSupabase()
        ..registerHandler(
          'list_tenant_members',
          (_) async => throw RpcException('PERMISSION_DENIED'),
        );
      final gateway = _gateway(supabase);

      expect(
        () => gateway.listTenantMembers(tenantId: 'tenant-1'),
        throwsA(
          isA<ApplicationException>().having(
            (e) => e.message,
            'message',
            contains('PERMISSION_DENIED'),
          ),
        ),
      );
    });
  });
}

SupabaseIamAccessGateway _gateway(FakeIamRpcSupabase supabase) {
  return SupabaseIamAccessGateway(
    rpcClient: SupabaseSchemaRpcClient(
      supabase: supabase,
      schema: 'iam',
      mapError: (error, [stackTrace]) =>
          error is RpcException ? error : RpcException(error.toString()),
    ),
  );
}
