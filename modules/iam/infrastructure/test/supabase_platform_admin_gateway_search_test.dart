import 'package:test/test.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_infrastructure/src/domain/platform/supabase_platform_admin_gateway.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'support/fake_iam_rpc_supabase.dart';

void main() {
  test('getPlatformTenant maps version for lifecycle concurrency', () async {
    final supabase = FakeIamRpcSupabase();
    supabase.registerHandler('get_platform_tenant', (params) async {
      return {
        'tenant_id': 'tenant-2',
        'name': 'My Store',
        'code': '1686ef0a',
        'status': 'suspended',
        'created_at': '2026-01-01T00:00:00.000Z',
        'last_activity_at': '2026-08-05T06:25:34.000Z',
        'version': 3,
        'members': const <Map<String, dynamic>>[],
      };
    });
    final gateway = SupabasePlatformAdminGateway(
      rpcClient: SupabaseSchemaRpcClient(
        supabase: supabase,
        schema: 'iam',
        mapError: (error, [stackTrace]) => RpcException(error.toString()),
      ),
    );

    final detail = await gateway.getPlatformTenant('tenant-2');

    expect(detail.version, 3);
    expect(detail.status.name, 'suspended');
    expect(detail.lastActivityAt, DateTime.parse('2026-08-05T06:25:34.000Z'));
  });

  test('getPlatformTenant collapses duplicate member rows by user id', () async {
    final supabase = FakeIamRpcSupabase();
    supabase.registerHandler('get_platform_tenant', (params) async {
      expect(params?['p_tenant_id'], 'tenant-1');
      return {
        'tenant_id': 'tenant-1',
        'name': 'Minh Phat',
        'code': 'TEN-001',
        'status': 'active',
        'created_at': '2026-01-01T00:00:00.000Z',
        'version': 1,
        'members': [
          {
            'user_id': 'user-owner',
            'full_name': 'Owner User',
            'email': 'owner@example.com',
            'role': 'owner',
            'is_owner': true,
          },
          {
            'user_id': 'user-chien',
            'full_name': 'Đỗ Sỹ Chiến',
            'email': 'sychien212@gmail.com',
            'role': 'accountant',
            'is_owner': false,
          },
          {
            'user_id': 'user-chien',
            'full_name': 'Đỗ Sỹ Chiến',
            'email': 'sychien212@gmail.com',
            'role': 'staff',
            'is_owner': false,
          },
        ],
      };
    });
    final gateway = SupabasePlatformAdminGateway(
      rpcClient: SupabaseSchemaRpcClient(
        supabase: supabase,
        schema: 'iam',
        mapError: (error, [stackTrace]) => RpcException(error.toString()),
      ),
    );

    final detail = await gateway.getPlatformTenant('tenant-1');

    expect(detail.members.map((m) => m.userId), ['user-owner', 'user-chien']);
    expect(detail.members.last.roleLabel, 'accountant');
  });

  test('getPlatformTenant maps DB role labels for tenant members', () async {
    final supabase = FakeIamRpcSupabase();
    supabase.registerHandler('get_platform_tenant', (params) async {
      return {
        'tenant_id': 'tenant-1',
        'name': 'Minh Phat',
        'code': 'TEN-001',
        'status': 'active',
        'created_at': '2026-01-01T00:00:00.000Z',
        'version': 1,
        'members': [
          {
            'user_id': 'user-owner',
            'full_name': 'Owner User',
            'email': 'owner@example.com',
            'role': 'owner',
            'role_label': 'Chủ cửa hàng',
            'is_owner': true,
          },
          {
            'user_id': 'user-manager',
            'full_name': 'Đỗ Sỹ Chiến',
            'email': 'manager@example.com',
            'role': 'manager',
            'role_label': 'Quản lý',
            'is_owner': false,
          },
        ],
      };
    });
    final gateway = SupabasePlatformAdminGateway(
      rpcClient: SupabaseSchemaRpcClient(
        supabase: supabase,
        schema: 'iam',
        mapError: (error, [stackTrace]) => RpcException(error.toString()),
      ),
    );

    final detail = await gateway.getPlatformTenant('tenant-1');

    expect(detail.members.map((m) => m.roleLabel), [
      'Chủ cửa hàng',
      'Quản lý',
    ]);
  });

  test('searchPlatformUsers maps full_name for onboarding owner card', () async {
    final supabase = FakeIamRpcSupabase();
    supabase.registerHandler('search_platform_users', (params) async {
      expect(params?['p_query'], 'lan');
      expect(params?['p_status'], 'active');
      expect(params?['p_cursor'], isNull);
      expect(params?['p_page_size'], 20);
      return {
        'items': [
          {
            'user_id': 'user-lan',
            'full_name': 'Lê Thị Lan',
            'email': 'lan@gmail.com',
            'status': 'active',
            'created_at': '2026-01-01T00:00:00.000Z',
          },
        ],
        'next_cursor': null,
      };
    });
    final gateway = SupabasePlatformAdminGateway(
      rpcClient: SupabaseSchemaRpcClient(
        supabase: supabase,
        schema: 'iam',
        mapError: (error, [stackTrace]) => RpcException(error.toString()),
      ),
    );

    final page = await gateway.searchPlatformUsers(
      query: 'lan',
      status: PlatformUserStatus.active,
    );

    expect(page.items, hasLength(1));
    expect(page.items.single.fullName, 'Lê Thị Lan');
    expect(page.items.single.email, 'lan@gmail.com');
  });
}
