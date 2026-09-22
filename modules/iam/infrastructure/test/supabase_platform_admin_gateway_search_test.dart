import 'package:test/test.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_domain/domain.dart';
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
            'role': 'store_owner',
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
            'role': 'store_owner',
            'role_label': 'Chủ cửa hàng',
            'is_owner': true,
          },
          {
            'user_id': 'user-staff',
            'full_name': 'Đỗ Sỹ Chiến',
            'email': 'staff@example.com',
            'role': 'staff',
            'role_label': 'Nhân viên bán hàng',
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
      'Nhân viên bán hàng',
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
            'phone_number': '0901234567',
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
    expect(page.items.single.phoneNumber, '0901234567');
  });

  test(
    'getPlatformTenant maps owner_email_verified false unverifiedEmail on provisioning',
    () async {
      final supabase = FakeIamRpcSupabase();
      supabase.registerHandler('get_platform_tenant', (params) async {
        return {
          'tenant_id': 'tenant-prov',
          'name': 'Sỹ Chiến',
          'code': 'da84bd3c',
          'status': 'provisioning',
          'created_at': '2026-09-10T14:47:00.000Z',
          'version': 1,
          'owner_user_id': 'user-chien',
          'owner_name': 'Sỹ Chiến',
          'owner_email': 'sychien212@gmail.com',
          'owner_role': 'store_owner',
          'owner_email_verified': true,
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

      final detail = await gateway.getPlatformTenant('tenant-prov');

      expect(detail.status, TenantLifecycleStatus.provisioning);
      expect(detail.unverifiedEmail, isFalse);
      expect(detail.ownerEmail, 'sychien212@gmail.com');
    },
  );

  test('getPlatformTenant maps owner invitation metadata wire keys', () async {
    final supabase = FakeIamRpcSupabase();
    supabase.registerHandler('get_platform_tenant', (params) async {
      return {
        'tenant_id': 'tenant-inv',
        'name': 'Pending Owner',
        'code': 'TEN-INV',
        'status': 'provisioning',
        'created_at': '2026-09-10T14:47:00.000Z',
        'version': 1,
        'owner_user_id': null,
        'owner_name': 'Lan Le',
        'owner_email': 'owner@example.com',
        'owner_role': 'store_owner',
        'owner_email_verified': false,
        'members': const <Map<String, dynamic>>[],
        'owner_invitation_email': 'owner@example.com',
        'owner_invitation_state': 'pending',
        'owner_invitation_expires_at': '2026-09-17T14:47:00.000Z',
        'owner_invitation_given_name': 'Lan',
        'owner_invitation_family_name': 'Le',
        'owner_invitation_phone': '0901234567',
      };
    });
    final gateway = SupabasePlatformAdminGateway(
      rpcClient: SupabaseSchemaRpcClient(
        supabase: supabase,
        schema: 'iam',
        mapError: (error, [stackTrace]) => RpcException(error.toString()),
      ),
    );

    final detail = await gateway.getPlatformTenant('tenant-inv');

    expect(detail.ownerInvitationEmail, 'owner@example.com');
    expect(detail.ownerInvitationState, 'pending');
    expect(
      detail.ownerInvitationExpiresAt,
      DateTime.parse('2026-09-17T14:47:00.000Z'),
    );
    expect(detail.ownerInvitationGivenName, 'Lan');
    expect(detail.ownerInvitationFamilyName, 'Le');
    expect(detail.ownerInvitationPhone, '0901234567');
    expect(detail.members, isEmpty);
  });
}
