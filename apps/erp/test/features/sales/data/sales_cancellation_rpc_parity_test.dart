// ignore_for_file: implementation_imports, depend_on_referenced_packages

import 'dart:convert';

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/sales/data/mappers/sales_cancellation_json.dart';
import 'package:erp/features/sales/data/models/sales_cancellation_request.dart';
import 'package:erp/features/sales/data/sales_cancellation_repository.dart';
import 'package:erp/features/sales/presentation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_sales_infrastructure/infrastructure.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'sales_post_sale_parity_expectations.dart';

class _RecordingRpc implements SupabaseRpc {
  final calls = <({String schema, String fn, Map<String, dynamic>? params})>[];
  Object? result;

  @override
  Future<dynamic> call(String schema, String fn, {Map<String, dynamic>? params}) async {
    calls.add((schema: schema, fn: fn, params: params));
    if (result is Exception) throw result!;
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeRpcClient implements IRpcClient {
  _FakeRpcClient({this.error});
  final Object? error;

  @override
  Future<Map<String, dynamic>> call(String procedure, {Map<String, dynamic>? params}) async {
    if (error != null) throw error!;
    return <String, dynamic>{};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  group('sales cancellation rpc parity (old)', () {
    test('params_cancel_precheck', () {
      final query = PrecheckSalesOrderCancellationQuery(
        id: parityQueryId,
        tenantId: parityTenantId,
        actorId: parityActorId,
        salesOrderId: parityOrderId,
        expectedSourceVersion: 7,
      );
      final params = SalesOrderCancellationRpcMapper.precheckParams(query);
      expect(params, equals(expectedCancelPrecheckParams()));
    });

    test('params_cancel_confirm', () {
      final command = ConfirmSalesOrderCancellationCommand(
        id: parityCommandId,
        tenantId: parityTenantId,
        actorId: parityActorId,
        salesOrderId: parityOrderId,
        reason: const CancellationReasonDto(reasonText: 'Khách yêu cầu huỷ'),
        idempotencyKey: 'sales-order-cancellation:$parityCommandId',
        payloadHash: expectedCancelHash,
        correlationId: parityCorrelationId,
        expectedVersion: 7,
        expectedSettlementVersion: 3,
      );
      final params = SalesOrderCancellationRpcMapper.confirmParams(command);
      expect(params, equals(expectedCancelConfirmParams()));
    });

    test('parse_cancel_precheck', () {
      final ready = SalesOrderCancellationRpcMapper.precheckFromJson(
        sampleCancelPrecheckJson(allowed: true),
      );
      expect(ready.allowed, isTrue);
      expect(ready.sourceVersion, 7);
      expect(ready.sourceSettlementVersion, 3);
      expect(ready.blockers, isEmpty);

      final blocked = SalesOrderCancellationRpcMapper.precheckFromJson(
        sampleCancelPrecheckJson(allowed: false),
      );
      expect(blocked.allowed, isFalse);
      expect(blocked.blockers.single.code, 'PAYMENT_ALREADY_COLLECTED');
    });

    test('parse_cancel_result', () {
      final result = SalesOrderCancellationRpcMapper.resultFromJson(
        sampleCancelResultJson(),
      );
      expect(result.cancellationId, 'cancellation-1');
      expect(result.salesOrderId, parityOrderId);
      expect(result.salesOrderVersion, 8);
      expect(result.status, SalesOrderCancellationStatus.confirmed);
    });

    test('parse_cancel_rejects_unknown_key', () {
      expect(
        () => SalesOrderCancellationRpcMapper.precheckFromJson(<String, dynamic>{
          ...sampleCancelPrecheckJson(),
          'unknownKey': 123,
        }),
        throwsFormatException,
      );
    });

    test('hash_cancel_fixed', () {
      final factory = SalesOrderCancellationAttemptFactory(
        newAttemptId: () => parityCommandId,
      );
      final attempt = factory.create(
        tenantId: parityTenantId,
        actorId: parityActorId,
        salesOrderId: parityOrderId,
        expectedOrderVersion: 7,
        expectedSettlementVersion: 3,
        reasonText: 'Khách yêu cầu huỷ',
        correlationId: parityCorrelationId,
      );
      expect(attempt.payloadHash, expectedCancelHash);
    });

    group('gateway error mapping C8', () {
      for (final code in <String>{
        'NOT_FOUND',
        'PERMISSION_DENIED',
        'DATA_SCOPE_DENIED',
        'CANCELLATION_BLOCKED',
        'STALE_VERSION',
        'IDEMPOTENCY_CONFLICT',
        'IMPACT_PENDING',
        'DEPENDENCY_UNAVAILABLE',
      }) {
        test('preserves stable $code error envelope', () async {
          final gateway = SupabaseSalesOrderCancellationGateway(
            rpcClient: _FakeRpcClient(
              error: RpcException(
                jsonEncode(<String, dynamic>{'code': code, 'message': 'test'}),
              ),
            ),
          );
          await expectLater(
            () => gateway.precheck(
              PrecheckSalesOrderCancellationQuery(
                id: parityQueryId,
                tenantId: parityTenantId,
                actorId: parityActorId,
                salesOrderId: parityOrderId,
                expectedSourceVersion: 7,
              ),
            ),
            throwsA(isA<SalesContractException>().having((e) => e.code, 'code', code)),
          );
        });
      }
    });
  });

  group('sales cancellation rpc parity (new)', () {
    test('params_cancel_precheck', () async {
      final rpc = _RecordingRpc()..result = sampleCancelPrecheckJson();
      final repo = SalesCancellationRepository(
        rpc: rpc,
        tenantId: () async => parityTenantId,
        actorId: () async => parityActorId,
        newId: () => parityQueryId,
      );
      final result = await repo.precheck(
        salesOrderId: parityOrderId,
        expectedSourceVersion: 7,
      );
      expect(rpc.calls.single.schema, 'sales');
      expect(rpc.calls.single.fn, 'precheck_sales_order_cancellation');
      expect(rpc.calls.single.params, equals(expectedCancelPrecheckParams()));
      expect(result.allowed, isTrue);
    });

    test('params_cancel_confirm', () async {
      final rpc = _RecordingRpc()..result = sampleCancelResultJson();
      final repo = SalesCancellationRepository(
        rpc: rpc,
        tenantId: () async => parityTenantId,
        actorId: () async => parityActorId,
        newId: () => parityCommandId,
      );
      final request = const SalesOrderCancellationRequest(
        commandId: parityCommandId,
        salesOrderId: parityOrderId,
        reasonText: 'Khách yêu cầu huỷ',
        idempotencyKey: 'sales-order-cancellation:$parityCommandId',
        payloadHash: expectedCancelHash,
        correlationId: parityCorrelationId,
        expectedOrderVersion: 7,
        expectedSettlementVersion: 3,
      );
      final result = await repo.confirm(request);
      expect(rpc.calls.single.schema, 'sales');
      expect(rpc.calls.single.fn, 'confirm_sales_order_cancellation');
      expect(rpc.calls.single.params, equals(expectedCancelConfirmParams()));
      expect(result.status, SalesOrderCancellationStatus.confirmed);
    });

    test('parse_cancel_precheck', () {
      final ready = SalesCancellationJson.precheckFromJson(
        sampleCancelPrecheckJson(allowed: true),
      );
      expect(ready.allowed, isTrue);
      expect(ready.sourceVersion, 7);
      expect(ready.sourceSettlementVersion, 3);
      expect(ready.blockers, isEmpty);

      final blocked = SalesCancellationJson.precheckFromJson(
        sampleCancelPrecheckJson(allowed: false),
      );
      expect(blocked.allowed, isFalse);
      expect(blocked.blockers.single.code, 'PAYMENT_ALREADY_COLLECTED');
    });

    test('parse_cancel_result', () {
      final result = SalesCancellationJson.resultFromJson(
        sampleCancelResultJson(),
      );
      expect(result.cancellationId, 'cancellation-1');
      expect(result.salesOrderId, parityOrderId);
      expect(result.salesOrderVersion, 8);
      expect(result.status, SalesOrderCancellationStatus.confirmed);
    });

    test('parse_cancel_rejects_unknown_key', () async {
      final rpc = _RecordingRpc()
        ..result = <String, dynamic>{
          ...sampleCancelPrecheckJson(),
          'unexpectedKey': true,
        };
      final repo = SalesCancellationRepository(
        rpc: rpc,
        tenantId: () async => parityTenantId,
        actorId: () async => parityActorId,
        newId: () => parityQueryId,
      );
      await expectLater(
        () => repo.precheck(salesOrderId: parityOrderId, expectedSourceVersion: 7),
        throwsA(isA<AppException>().having((e) => e.code, 'code', 'SYSTEM_ERROR')),
      );
    });
  });
}
