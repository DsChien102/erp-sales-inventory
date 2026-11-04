import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/dashboard/data/default_pair_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

class _Rpc extends SupabaseRpc {
  _Rpc()
    : super(
        SupabaseClient(
          'http://127.0.0.1',
          'anon',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );

  final calls = <({String schema, String fn, Map<String, dynamic>? params})>[];
  dynamic next;
  Object? nextError;

  @override
  Future<dynamic> call(
    String schema,
    String fn, {
    Map<String, dynamic>? params = const {},
  }) async {
    calls.add((schema: schema, fn: fn, params: params));
    if (nextError != null) throw nextError!;
    return next;
  }
}

void main() {
  group('DefaultPairRepository', () {
    late _Rpc rpc;
    late DefaultPairRepository repository;

    setUp(() {
      rpc = _Rpc();
      repository = DefaultPairRepository(
        rpc: rpc,
        tenantId: () async => 't1',
      );
    });

    test('get_calls_one_rpc_with_tenant', () async {
      rpc.next = {
        'storeId': 's1',
        'storeName': 'CH',
        'warehouseId': 'w1',
        'warehouseName': 'Kho mặc định',
      };

      final result = await repository.get();

      expect(rpc.calls, hasLength(1));
      expect(rpc.calls.single.schema, 'inventory');
      expect(rpc.calls.single.fn, 'get_default_store_warehouse_pair');
      expect(rpc.calls.single.params, {'p_tenant_id': 't1'});

      expect(result.storeId, 's1');
      expect(result.storeName, 'CH');
      expect(result.warehouseId, 'w1');
      expect(result.warehouseName, 'Kho mặc định');
      expect(result.replayed, isFalse);
    });

    test('ensure_reads_replayed', () async {
      rpc.next = {
        'storeId': 's1',
        'storeName': 'CH',
        'warehouseId': 'w1',
        'warehouseName': 'Kho mặc định',
        'replayed': true,
      };

      final result = await repository.ensure();

      expect(rpc.calls, hasLength(1));
      expect(rpc.calls.single.schema, 'inventory');
      expect(rpc.calls.single.fn, 'ensure_default_store_warehouse_pair');
      expect(rpc.calls.single.params?['p_tenant_id'], 't1');
      expect(result.replayed, isTrue);
    });

    test('ensure_keeps_one_correlation_id', () async {
      rpc.next = {
        'storeId': 's1',
        'storeName': 'CH',
        'warehouseId': 'w1',
        'warehouseName': 'Kho mặc định',
        'replayed': false,
      };

      await repository.ensure();
      await repository.ensure();

      expect(rpc.calls, hasLength(2));
      final corr1 = rpc.calls[0].params?['p_correlation_id'] as String?;
      final corr2 = rpc.calls[1].params?['p_correlation_id'] as String?;

      expect(corr1, isNotNull);
      expect(corr1, equals(corr2));
      expect(corr1, matches(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
    });

    test('get_propagates_app_exception', () async {
      rpc.nextError = const AppException('DEFAULT_PAIR_MISSING');

      await expectLater(
        repository.get(),
        throwsA(
          isA<AppException>().having((e) => e.code, 'code', 'DEFAULT_PAIR_MISSING'),
        ),
      );
    });
  });
}
