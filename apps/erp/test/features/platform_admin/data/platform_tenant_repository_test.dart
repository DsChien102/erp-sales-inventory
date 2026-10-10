import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/session/models/tenant_context.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/platform_admin/data/models/platform_tenant.dart';
import 'package:erp/features/platform_admin/data/platform_tenant_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRpc extends Mock implements SupabaseRpc {}

void main() {
  late _MockRpc rpc;
  late PlatformTenantRepository repository;
  late Map<String, dynamic> params;
  late String function;

  setUp(() {
    rpc = _MockRpc();
    repository = PlatformTenantRepository(rpc: rpc);
    params = {};
    function = '';
  });

  void stubCall(dynamic result) {
    when(() => rpc.call(any(), any(), params: any(named: 'params'))).thenAnswer((invocation) async {
      expect(invocation.positionalArguments.first, 'iam');
      function = invocation.positionalArguments[1] as String;
      params = Map<String, dynamic>.from(invocation.namedArguments[#params] as Map);
      return result;
    });
  }

  group('models', () {
    test('PlatformTenantSummary.fromJson maps wire fields', () {
      final value = PlatformTenantSummary.fromJson({
        'tenant_id': 't-1',
        'name': 'Mậu Hiền',
        'code': 'TEN-1',
        'status': 'suspended',
        'created_at': '2026-07-10T10:00:00Z',
        'owner_name': '  ',
        'owner_email': 'lan@example.com',
        'member_count': 3,
      });

      expect(value.tenantId, 't-1');
      expect(value.status, TenantStatus.suspended);
      expect(value.ownerName, isNull);
      expect(value.ownerEmail, 'lan@example.com');
      expect(value.memberCount, 3);
    });

    test('PlatformTenantDetail.fromJson keeps version and drops duplicate members', () {
      final value = PlatformTenantDetail.fromJson({
        'tenant_id': 't-1',
        'name': 'Mậu Hiền',
        'code': 'TEN-1',
        'status': 'active',
        'version': 7,
        'created_at': '2026-07-10T10:00:00Z',
        'last_activity_at': '2026-07-13T09:18:00Z',
        'owner_user_id': 'u-1',
        'owner_name': 'Lê Thị Lan',
        'owner_email': 'lan@example.com',
        'owner_role': 'Chủ cửa hàng',
        'members': [
          {'user_id': 'u-1', 'full_name': 'Lê Thị Lan', 'role_label': 'Chủ cửa hàng', 'is_owner': true},
          {'user_id': 'u-1', 'full_name': 'Trùng', 'is_owner': false},
          {'user_id': 'u-2', 'full_name': 'Trần Hoa', 'role': 'staff'},
        ],
      });

      expect(value.version, 7);
      expect(value.status, TenantStatus.active);
      expect(value.ownerUserId, 'u-1');
      expect(value.members.map((m) => m.userId), ['u-1', 'u-2']);
      expect(value.members.first.isOwner, isTrue);
      expect(value.members.last.roleLabel, 'staff');
      expect(value.suspendedAt, isNull);
    });

    test('PlatformTenantMember.fromJson falls back to role and empty strings', () {
      final value = PlatformTenantMember.fromJson({'user_id': 'u-9', 'role': 'warehouse'});

      expect(value.fullName, '');
      expect(value.email, '');
      expect(value.roleLabel, 'warehouse');
      expect(value.isOwner, isFalse);
    });
  });

  group('search', () {
    test('always sends all six parameters', () async {
      stubCall({'items': <Object?>[], 'next_cursor': null});

      await repository.search();

      expect(function, 'search_platform_tenants');
      expect(params.keys, [
        'p_query',
        'p_status',
        'p_readiness_state',
        'p_warning_code',
        'p_cursor',
        'p_page_size',
      ]);
      expect(params['p_query'], isNull);
      expect(params['p_status'], isNull);
      expect(params['p_readiness_state'], isNull);
      expect(params['p_warning_code'], isNull);
      expect(params['p_page_size'], 20);
    });

    test('trims the query and maps rows with the next cursor', () async {
      stubCall({
        'items': [
          {
            'tenant_id': 't-1',
            'name': 'A',
            'code': 'A1',
            'status': 'active',
            'created_at': '2026-07-10T10:00:00Z',
            'member_count': 2,
          },
        ],
        'next_cursor': '20',
      });

      final page = await repository.search(query: '  mậu  ', status: 'active', cursor: '0');

      expect(params['p_query'], 'mậu');
      expect(params['p_status'], 'active');
      expect(params['p_cursor'], '0');
      expect(page.items.single.tenantId, 't-1');
      expect(page.nextCursor, '20');
    });

    test('rejects statuses outside active, suspended and closed', () async {
      stubCall({'items': <Object?>[]});

      expect(
        () => repository.search(status: 'provisioning'),
        throwsA(isA<AppException>().having((e) => e.code, 'code', AppErrorCode.validation)),
      );
    });
  });

  group('commands', () {
    setUp(() => stubCall(null));

    test('suspend sends reason, version and key', () async {
      await repository.suspend('t-1', reason: 'Vi phạm', expectedVersion: 4, idempotencyKey: 'k');

      expect(function, 'suspend_platform_tenant');
      expect(params, {
        'p_tenant_id': 't-1',
        'p_reason': 'Vi phạm',
        'p_expected_version': 4,
        'p_idempotency_key': 'k',
      });
    });

    test('restore has no reason parameter', () async {
      await repository.restore('t-1', expectedVersion: 5, idempotencyKey: 'k');

      expect(function, 'restore_platform_tenant');
      expect(params.keys, ['p_tenant_id', 'p_expected_version', 'p_idempotency_key']);
    });

    test('close sends reason', () async {
      await repository.close('t-1', reason: 'Ngừng KD', expectedVersion: 5, idempotencyKey: 'k');

      expect(function, 'close_platform_tenant');
      expect(params['p_reason'], 'Ngừng KD');
    });

    test('transferOwnership sends the new owner id', () async {
      await repository.transferOwnership(
        't-1',
        newOwnerUserId: 'u-2',
        expectedVersion: 5,
        idempotencyKey: 'k',
      );

      expect(function, 'transfer_platform_tenant_ownership');
      expect(params['p_new_owner_user_id'], 'u-2');
      expect(params['p_expected_version'], 5);
    });
  });

  test('get maps the detail and reports an empty result as not found', () async {
    stubCall({
      'tenant_id': 't-1',
      'name': 'A',
      'code': 'A1',
      'status': 'active',
      'created_at': '2026-07-10T10:00:00Z',
    });
    expect((await repository.get('t-1')).tenantId, 't-1');
    expect(function, 'get_platform_tenant');
    expect(params, {'p_tenant_id': 't-1'});

    stubCall(null);
    expect(
      () => repository.get('t-1'),
      throwsA(isA<AppException>().having((e) => e.code, 'code', AppErrorCode.notFound)),
    );
  });

  test('listMembers maps table rows', () async {
    when(() => rpc.rows(any(), any(), params: any(named: 'params'))).thenAnswer(
      (_) async => [
        {'user_id': 'u-1', 'full_name': 'A', 'email': 'a@x', 'role_label': 'Kế toán', 'is_owner': false},
      ],
    );

    final members = await repository.listMembers('t-1');

    expect(members.single.userId, 'u-1');
    verify(
      () => rpc.rows('iam', 'list_platform_tenant_members', params: {'p_tenant_id': 't-1'}),
    ).called(1);
  });
}
