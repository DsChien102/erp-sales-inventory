import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/inventory/data/core/inventory_rpc.dart';

class MockSupabaseRpc extends Mock implements SupabaseRpc {}

void main() {
  late MockSupabaseRpc mockRpc;
  late InventoryRpc inventoryRpc;
  const testTenantId = 'tenant-123';

  setUp(() {
    mockRpc = MockSupabaseRpc();
    inventoryRpc = InventoryRpc(
      rpc: mockRpc,
      tenantId: () async => testTenantId,
    );
  });

  group('InventoryRpc', () {
    test('query_prepends_schema', () async {
      when(
        () => mockRpc.call(
          'inventory',
          'test_fn',
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) async => {'result': 'ok'});

      final res = await inventoryRpc.query('test_fn', {'foo': 'bar'});
      expect(res, {'result': 'ok'});
      verify(
        () => mockRpc.call(
          'inventory',
          'test_fn',
          params: {'p_tenant_id': testTenantId, 'foo': 'bar'},
        ),
      ).called(1);
    });

    test('query_attaches_tenant_id', () async {
      when(
        () => mockRpc.call(
          'inventory',
          'get_hub',
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) async => {'activated': true});

      await inventoryRpc.query('get_hub');
      verify(
        () => mockRpc.call(
          'inventory',
          'get_hub',
          params: {'p_tenant_id': testTenantId},
        ),
      ).called(1);
    });

    test('mutate_attaches_idempotency_key', () async {
      when(
        () => mockRpc.call(
          'inventory',
          'post_cmd',
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) async => {'status': 'done'});

      final res = await inventoryRpc.mutate(
        scope: 'goods_receipt',
        idempotencyKey: 'idem-key-1',
        fn: 'post_cmd',
        params: {'qty': 5},
      );

      expect(res, {'status': 'done'});
      verify(
        () => mockRpc.call(
          'inventory',
          'post_cmd',
          params: {
            'p_tenant_id': testTenantId,
            'p_idempotency_key': 'idem-key-1',
            'qty': 5,
          },
        ),
      ).called(1);
    });

    test('mutate_network_error_rethrows_network', () async {
      const networkError = AppException(AppErrorCode.network);
      when(
        () => mockRpc.call(
          'inventory',
          'post_cmd',
          params: any(named: 'params'),
        ),
      ).thenThrow(networkError);

      expect(
        () => inventoryRpc.mutate(
          scope: 'goods_receipt',
          idempotencyKey: 'idem-key-1',
          fn: 'post_cmd',
          params: {'qty': 5},
        ),
        throwsA(same(networkError)),
      );
    });

    test('mutate_business_error_rethrows_app_exception', () async {
      const businessError = AppException('INSUFFICIENT_STOCK');
      when(
        () => mockRpc.call(
          'inventory',
          'post_cmd',
          params: any(named: 'params'),
        ),
      ).thenThrow(businessError);

      expect(
        () => inventoryRpc.mutate(
          scope: 'goods_receipt',
          idempotencyKey: 'idem-key-1',
          fn: 'post_cmd',
          params: {'qty': 5},
        ),
        throwsA(same(businessError)),
      );
    });

    test('retry_uses_same_key', () async {
      const key = 'fixed-idem-key';
      when(
        () => mockRpc.call(
          'inventory',
          'post_cmd',
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) async => {'attempt': 1});

      await inventoryRpc.mutate(
        scope: 'receipt',
        idempotencyKey: key,
        fn: 'post_cmd',
        params: {},
      );

      await inventoryRpc.mutate(
        scope: 'receipt',
        idempotencyKey: key,
        fn: 'post_cmd',
        params: {},
      );

      verify(
        () => mockRpc.call(
          'inventory',
          'post_cmd',
          params: {
            'p_tenant_id': testTenantId,
            'p_idempotency_key': key,
          },
        ),
      ).called(2);
    });
  });
}
