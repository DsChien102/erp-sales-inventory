// ignore_for_file: implementation_imports, depend_on_referenced_packages

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/sales/data/sales_order_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sales_order_inquiry_parity_expectations.dart';

class _RecordingRpc implements SupabaseRpc {
  final calls = <({String schema, String fn, Map<String, dynamic>? params})>[];
  Object? result;

  @override
  Future<dynamic> call(String schema, String fn, {Map<String, dynamic>? params}) async {
    calls.add((schema: schema, fn: fn, params: params));
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  group('new', () {
    late _RecordingRpc rpc;
    late SalesOrderRepository repository;

    setUp(() {
      rpc = _RecordingRpc();
      repository = SalesOrderRepository(
        rpc: rpc,
        tenantId: () async => inquiryTenantId,
        actorId: () async => inquiryActorId,
        newId: () => inquiryQueryId,
      );
    });

    test('params_list_all_filters', () async {
      rpc.result = samplePagedListJson();
      await repository.list(filter: fullFilter());
      expect(rpc.calls.single.schema, 'sales');
      expect(rpc.calls.single.fn, 'list_sales_orders');
      expect(rpc.calls.single.params, equals(expectedListParams(filter: fullFilter())));
    });

    test('params_list_null_filter', () async {
      rpc.result = samplePagedListJson();
      await repository.list(filter: null);
      expect(rpc.calls.single.schema, 'sales');
      expect(rpc.calls.single.fn, 'list_sales_orders');
      expect(rpc.calls.single.params, equals(expectedListParams(filter: null)));
    });

    test('params_search', () async {
      rpc.result = samplePagedListJson();
      await repository.search(searchText: 'SO-125', filter: fullFilter());
      expect(rpc.calls.single.schema, 'sales');
      expect(rpc.calls.single.fn, 'search_sales_orders');
      expect(
        rpc.calls.single.params,
        equals(expectedSearchParams(searchText: 'SO-125', filter: fullFilter())),
      );
    });

    test('params_detail', () async {
      rpc.result = sampleDetailJson();
      await repository.getDetail(salesOrderId: inquiryOrderId);
      expect(rpc.calls.single.schema, 'sales');
      expect(rpc.calls.single.fn, 'get_sales_order_detail');
      expect(
        rpc.calls.single.params,
        equals(
          expectedOrderScopedParams(salesOrderId: inquiryOrderId, expectedSourceVersion: null),
        ),
      );
    });

    test('params_timeline', () async {
      rpc.result = sampleTimelineJson();
      await repository.getTimeline(salesOrderId: inquiryOrderId, expectedSourceVersion: 7);
      expect(rpc.calls.single.schema, 'sales');
      expect(rpc.calls.single.fn, 'get_sales_order_timeline');
      expect(
        rpc.calls.single.params,
        equals(expectedOrderScopedParams(salesOrderId: inquiryOrderId, expectedSourceVersion: 7)),
      );
    });

    test('params_return_summary', () async {
      rpc.result = sampleReturnSummaryJson();
      await repository.getReturnSummary(salesOrderId: inquiryOrderId, expectedSourceVersion: 7);
      expect(rpc.calls.single.schema, 'sales');
      expect(rpc.calls.single.fn, 'get_sales_order_return_summary');
      expect(
        rpc.calls.single.params,
        equals(expectedOrderScopedParams(salesOrderId: inquiryOrderId, expectedSourceVersion: 7)),
      );
    });

    test('params_available_actions', () async {
      rpc.result = sampleAvailableActionsJson();
      await repository.getAvailableActions(salesOrderId: inquiryOrderId, expectedSourceVersion: 7);
      expect(rpc.calls.single.schema, 'sales');
      expect(rpc.calls.single.fn, 'get_available_post_sale_actions');
      expect(
        rpc.calls.single.params,
        equals(expectedOrderScopedParams(salesOrderId: inquiryOrderId, expectedSourceVersion: 7)),
      );
    });

    test('params_cancellation', () async {
      rpc.result = sampleCancellationDetailJson();
      await repository.getCancellation(salesOrderId: inquiryOrderId, expectedSourceVersion: 8);
      expect(rpc.calls.single.schema, 'sales');
      expect(rpc.calls.single.fn, 'get_sales_order_cancellation');
      expect(
        rpc.calls.single.params,
        equals(expectedOrderScopedParams(salesOrderId: inquiryOrderId, expectedSourceVersion: 8)),
      );
    });

    test('parse_paged_list', () async {
      rpc.result = samplePagedListJson();
      final dto = await repository.list();
      expectPagedListDto(dto);
    });

    test('parse_detail', () async {
      rpc.result = sampleDetailJson();
      final dto = await repository.getDetail(salesOrderId: inquiryOrderId);
      expectDetailDto(dto);
    });

    test('parse_timeline', () async {
      rpc.result = sampleTimelineJson();
      final dto = await repository.getTimeline(salesOrderId: inquiryOrderId);
      expectTimelineDto(dto);
    });

    test('parse_return_summary', () async {
      rpc.result = sampleReturnSummaryJson();
      final dto = await repository.getReturnSummary(salesOrderId: inquiryOrderId);
      expectReturnSummaryDto(dto);
    });

    test('parse_available_actions', () async {
      rpc.result = sampleAvailableActionsJson();
      final dto = await repository.getAvailableActions(salesOrderId: inquiryOrderId);
      expectAvailableActionsDto(dto);
    });

    test('parse_cancellation', () async {
      rpc.result = sampleCancellationDetailJson();
      final dto = await repository.getCancellation(salesOrderId: inquiryOrderId);
      expectCancellationDetailDto(dto);
    });

    test('parse_cancellation_rejects_unknown_key', () async {
      rpc.result = sampleCancellationDetailJson()..['unknown'] = 'bad';
      await expectLater(
        repository.getCancellation(salesOrderId: inquiryOrderId),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'SYSTEM_ERROR')),
      );
    });
  });
}
