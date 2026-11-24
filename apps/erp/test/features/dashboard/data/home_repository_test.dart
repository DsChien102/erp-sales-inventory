import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/dashboard/data/home_repository.dart';
import 'package:erp/features/dashboard/data/models/home_summary.dart';
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

Map<String, dynamic> sampleJson({Object? uninvoiced = 2}) => {
  'today': '2026-11-23',
  'revenue_today': 8420000,
  'revenue_yesterday': 7135593,
  'revenue_week': [
    for (final (i, v) in [6100000, 7400000, 5200000, 8900000, 7100000, 9600000, 8420000].indexed)
      {'day': '2026-11-${17 + i}', 'revenue': v},
  ],
  'orders_today': 12,
  'orders_yesterday': 9,
  'orders_by_payment': {'cash': 7, 'bank': 4, 'debt': 1},
  'orders_uninvoiced': uninvoiced,
  'cash_in_today': {'total': 9560000, 'cash': 4150000, 'bank': 5410000},
  'receivable_total': 24600000,
  'receivable_overdue_count': 3,
};

void main() {
  group('HomeSummary', () {
    test('fromJson parses sample', () {
      final s = HomeSummary.fromJson(sampleJson());
      expect(s.today, DateTime(2026, 11, 23));
      expect(s.revenueToday, 8420000);
      expect(s.revenueYesterday, 7135593);
      expect(s.revenueWeek, hasLength(7));
      expect(s.revenueWeek.first.day, DateTime(2026, 11, 17));
      expect(s.revenueWeek.last.revenueMinor, 8420000);
      expect(s.ordersToday, 12);
      expect(s.ordersYesterday, 9);
      expect((s.ordersCash, s.ordersBank, s.ordersDebt), (7, 4, 1));
      expect(s.ordersUninvoiced, 2);
      expect((s.cashInTotal, s.cashInCash, s.cashInBank), (9560000, 4150000, 5410000));
      expect(s.receivableTotal, 24600000);
      expect(s.receivableOverdueCount, 3);
    });

    test('fromJson keeps null orders_uninvoiced', () {
      expect(HomeSummary.fromJson(sampleJson(uninvoiced: null)).ordersUninvoiced, isNull);
    });
  });

  group('HomeRepository', () {
    late _Rpc rpc;
    late HomeRepository repository;

    setUp(() {
      rpc = _Rpc();
      repository = HomeRepository(rpc: rpc, tenantId: () async => 't1');
    });

    test('fetch calls sales.get_home_summary with p_tenant_id', () async {
      rpc.next = sampleJson();
      final s = await repository.fetch();
      expect(rpc.calls, hasLength(1));
      expect(rpc.calls.single.schema, 'sales');
      expect(rpc.calls.single.fn, 'get_home_summary');
      expect(rpc.calls.single.params, {'p_tenant_id': 't1'});
      expect(s.ordersToday, 12);
    });

    test('fetch propagates AppException', () async {
      rpc.nextError = const AppException('PERMISSION_DENIED');
      await expectLater(
        repository.fetch(),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'PERMISSION_DENIED')),
      );
    });
  });
}
