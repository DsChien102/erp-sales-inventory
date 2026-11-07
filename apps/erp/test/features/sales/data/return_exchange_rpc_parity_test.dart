// ignore_for_file: implementation_imports, depend_on_referenced_packages

import 'dart:convert';

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/sales/data/mappers/return_exchange_json.dart';
import 'package:erp/features/sales/data/models/return_exchange_requests.dart';
import 'package:erp/features/sales/data/return_exchange_repository.dart';
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
  group('return exchange rpc parity (old)', () {
    test('params_precheck', () {
      final query = PrecheckReturnExchangeQuery(
        id: parityQueryId,
        tenantId: parityTenantId,
        actorId: parityActorId,
        salesOrderId: parityOrderId,
        expectedSourceVersion: 7,
      );
      final params = ReturnExchangeRpcMapper.precheckParams(query);
      expect(params, equals(expectedReturnExchangePrecheckParams()));
    });

    test('params_returnable', () {
      final query = GetReturnableOrderLinesQuery(
        id: parityQueryId,
        tenantId: parityTenantId,
        actorId: parityActorId,
        salesOrderId: parityOrderId,
        expectedSourceVersion: null,
      );
      final params = ReturnExchangeRpcMapper.getReturnableParams(query);
      expect(params, equals(expectedReturnableParams()));
    });

    test('params_preview', () {
      final query = PreviewReturnExchangePricingQuery(
        id: parityQueryId,
        tenantId: parityTenantId,
        actorId: parityActorId,
        salesOrderId: parityOrderId,
        lines: samplePricingLines,
      );
      final params = ReturnExchangeRpcMapper.previewPricingParams(query);
      expect(params, equals(expectedPreviewPricingParams()));
    });

    test('params_detail', () {
      final query = GetReturnExchangeDetailQuery(
        id: parityQueryId,
        tenantId: parityTenantId,
        actorId: parityActorId,
        returnExchangeId: parityReturnExchangeId,
        expectedVersion: null,
      );
      final params = ReturnExchangeRpcMapper.detailParams(query);
      expect(params, equals(expectedReturnExchangeDetailParams()));
    });

    test('reference_decision_from_lines', () async {
      final decision = await UnavailableReturnExchangeReferencePort().evaluate(
        tenantId: parityTenantId,
        actorId: parityActorId,
        salesOrderId: parityOrderId,
        lines: sampleParityLines,
        reserveExchangeStock: false,
      );
      final json = ReturnExchangeRpcMapper.referenceDecisionToJson(decision);
      expect(json, equals(expectedReferenceDecision()));
    });

    test('params_start', () async {
      final decision = await UnavailableReturnExchangeReferencePort().evaluate(
        tenantId: parityTenantId,
        actorId: parityActorId,
        salesOrderId: parityOrderId,
        lines: sampleParityLines,
        reserveExchangeStock: false,
      );
      final command = StartReturnExchangeCommand(
        id: parityCommandId,
        tenantId: parityTenantId,
        actorId: parityActorId,
        salesOrderId: parityOrderId,
        entrySource: ReturnExchangeEntrySource.standard,
        lines: sampleParityLines,
        idempotencyKey: 'return-exchange:start:$parityCommandId',
        payloadHash: expectedStartHash,
        correlationId: parityCorrelationId,
        expectedVersion: 7,
      );
      final params = ReturnExchangeRpcMapper.startParams(
        command,
        referenceDecision: decision,
      );
      expect(
        params,
        equals(
          expectedStartParams(
            lines: params['lines'] as List<Map<String, dynamic>>,
            referenceDecision: expectedReferenceDecision(),
          ),
        ),
      );
    });

    test('params_update', () async {
      final decision = await UnavailableReturnExchangeReferencePort().evaluate(
        tenantId: parityTenantId,
        actorId: parityActorId,
        salesOrderId: parityOrderId,
        lines: sampleParityLines,
        reserveExchangeStock: false,
      );
      final command = UpdateReturnExchangeCommand(
        id: parityCommandId,
        tenantId: parityTenantId,
        actorId: parityActorId,
        returnExchangeId: parityReturnExchangeId,
        lines: sampleParityLines,
        idempotencyKey: 'return-exchange:update:$parityCommandId',
        payloadHash: 'hash-update-1',
        correlationId: parityCorrelationId,
        expectedVersion: 3,
      );
      final params = ReturnExchangeRpcMapper.updateParams(
        command,
        referenceDecision: decision,
      );
      expect(
        params,
        equals(
          expectedUpdateParams(
            lines: params['lines'] as List<Map<String, dynamic>>,
            payloadHash: 'hash-update-1',
            referenceDecision: expectedReferenceDecision(),
          ),
        ),
      );
    });

    test('params_cancel', () {
      final command = CancelReturnExchangeCommand(
        id: parityCommandId,
        tenantId: parityTenantId,
        actorId: parityActorId,
        returnExchangeId: parityReturnExchangeId,
        idempotencyKey: 'return-exchange:discard:$parityCommandId',
        payloadHash: 'hash-cancel-1',
        correlationId: parityCorrelationId,
        expectedVersion: 3,
      );
      final params = ReturnExchangeRpcMapper.cancelParams(command);
      expect(
        params,
        equals(expectedCancelReturnExchangeParams(payloadHash: 'hash-cancel-1')),
      );
    });

    test('params_cancel_null_version', () {
      final command = CancelReturnExchangeCommand(
        id: parityCommandId,
        tenantId: parityTenantId,
        actorId: parityActorId,
        returnExchangeId: parityReturnExchangeId,
        idempotencyKey: 'return-exchange:discard:$parityCommandId',
        payloadHash: 'hash-cancel-1',
        correlationId: parityCorrelationId,
        expectedVersion: null,
      );
      final params = ReturnExchangeRpcMapper.cancelParams(command);
      expect(
        params,
        equals(
          expectedCancelReturnExchangeParams(
            payloadHash: 'hash-cancel-1',
            expectedVersion: null,
          ),
        ),
      );
      expect(params.containsKey('expected_version'), isTrue);
      expect(params['expected_version'], isNull);
    });

    test('params_confirm', () async {
      final decision = await UnavailableReturnExchangeReferencePort().evaluate(
        tenantId: parityTenantId,
        actorId: parityActorId,
        salesOrderId: parityOrderId,
        lines: sampleParityLines,
        reserveExchangeStock: false,
      );
      final command = ConfirmReturnExchangeCommand(
        id: parityCommandId,
        tenantId: parityTenantId,
        actorId: parityActorId,
        returnExchangeId: parityReturnExchangeId,
        idempotencyKey: 'return-exchange:confirm:$parityCommandId',
        payloadHash: expectedConfirmHash,
        correlationId: parityCorrelationId,
        expectedVersion: 4,
        settledNowMinor: 100000,
        paymentMethod: SalesPaymentMethod.cash,
        paymentDueDate: DateTime(2026, 11, 20, 23, 30),
      );
      final params = ReturnExchangeRpcMapper.confirmParams(
        command,
        referenceDecision: decision,
      );
      expect(
        params,
        equals(
          expectedConfirmReturnExchangeParams(
            referenceDecision: expectedReferenceDecision(),
          ),
        ),
      );
      expect(params['payment_due_date'], '2026-11-20');
    });

    test('params_complete', () {
      final command = CompleteReturnExchangeCommand(
        id: parityCommandId,
        tenantId: parityTenantId,
        actorId: parityActorId,
        returnExchangeId: parityReturnExchangeId,
        idempotencyKey: 'return-exchange:complete:$parityCommandId',
        payloadHash: 'hash-complete-1',
        correlationId: parityCorrelationId,
        expectedVersion: 5,
      );
      final params = ReturnExchangeRpcMapper.completeParams(command);
      expect(
        params,
        equals(expectedCompleteReturnExchangeParams(payloadHash: 'hash-complete-1')),
      );
    });

    test('parse_precheck', () {
      final precheck = ReturnExchangeRpcMapper.precheckFromJson(
        sampleReturnExchangePrecheckJson(allowed: true),
      );
      expect(precheck.allowed, isTrue);
      expect(precheck.sourceVersion, 7);

      final blocked = ReturnExchangeRpcMapper.precheckFromJson(
        sampleReturnExchangePrecheckJson(allowed: false),
      );
      expect(blocked.allowed, isFalse);
      expect(blocked.blockers.single.code, 'ORDER_ALREADY_CANCELLED');
    });

    test('parse_returnable', () {
      final returnable = ReturnExchangeRpcMapper.returnableFromJson(
        sampleReturnableOrderLinesJson(),
      );
      expect(returnable.salesOrderId, parityOrderId);
      expect(returnable.sourceVersion, 7);
      expect(returnable.lines.single.salesOrderLineId, 'line-1');
    });

    test('parse_preview', () {
      final preview = ReturnExchangeRpcMapper.previewPricingFromJson(
        samplePreviewPricingJson(),
      );
      expect(preview.lines.single.productUnitId, 'unit-ex-full');
      expect(preview.lines.single.unitPrice.amountMinor, 60000);
    });

    test('parse_draft', () {
      final draft = ReturnExchangeRpcMapper.draftFromJson(sampleDraftJson());
      expect(draft.returnExchangeId, parityReturnExchangeId);
      expect(draft.version, 1);
      expect(draft.status, ReturnExchangeStatus.draft);
      expect(draft.lines.single.kind, ReturnExchangeLineKind.returnLine);
    });

    test('parse_result', () {
      final result = ReturnExchangeRpcMapper.resultFromJson(
        sampleReturnExchangeResultJson(),
      );
      expect(result.returnExchangeId, parityReturnExchangeId);
      expect(result.version, 4);
      expect(result.status, ReturnExchangeStatus.confirmed);
    });

    test('parse_valuation', () {
      final valuation = ReturnExchangeRpcMapper.valuationFromJson(
        sampleValuationJson(),
      );
      expect(valuation.returnValue.amountMinor, 50000);
      expect(valuation.exchangeValue.amountMinor, 120000);
      expect(valuation.settlementDifference.amountMinor, 70000);
      expect(valuation.settlementPlan.collectAmountMinor, 70000);
    });

    test('parse_detail_wrapped', () {
      final detail = ReturnExchangeRpcMapper.detailFromJson(
        sampleWrappedDetailJson(),
      );
      expect(detail.result.returnExchangeId, parityReturnExchangeId);
      expect(detail.result.status, ReturnExchangeStatus.confirmed);
      expect(detail.referenceNumber, 'RE-2026-0001');
      expect(detail.lines.single.kind, ReturnExchangeLineKind.returnLine);
      expect(detail.settlementPlan.netDifferenceMinor, 70000);
    });

    test('parse_detail_live', () {
      final detail = ReturnExchangeRpcMapper.detailFromJson(
        sampleLiveDetailJson(),
      );
      expect(detail.result.returnExchangeId, parityReturnExchangeId);
      expect(detail.result.status, ReturnExchangeStatus.confirmed);
      expect(detail.referenceNumber, 'RE-2026-0001');
      expect(detail.lines.single.kind, ReturnExchangeLineKind.returnLine);
      expect(detail.settlementPlan.netDifferenceMinor, 70000);
    });

    test('parse_rejects_unknown_key', () {
      expect(
        () => ReturnExchangeRpcMapper.precheckFromJson(<String, dynamic>{
          ...sampleReturnExchangePrecheckJson(),
          'unexpected': true,
        }),
        throwsFormatException,
      );
    });

    test('hash_start_fixed', () {
      final factory = SalesReturnExchangeAttemptFactory(
        newAttemptId: () => parityCommandId,
      );
      final attempt = factory.start(
        tenantId: parityTenantId,
        actorId: parityActorId,
        salesOrderId: parityOrderId,
        entrySource: ReturnExchangeEntrySource.standard,
        lines: sampleParityLines,
        expectedVersion: 7,
        correlationId: parityCorrelationId,
      );
      expect(attempt.payloadHash, expectedStartHash);
    });

    test('hash_confirm_fixed', () {
      final factory = SalesReturnExchangeAttemptFactory(
        newAttemptId: () => parityCommandId,
      );
      final attempt = factory.confirm(
        tenantId: parityTenantId,
        actorId: parityActorId,
        returnExchangeId: parityReturnExchangeId,
        expectedVersion: 4,
        settledNowMinor: 100000,
        paymentMethod: SalesPaymentMethod.cash,
        paymentDueDate: DateTime(2026, 11, 20, 23, 30),
        correlationId: parityCorrelationId,
      );
      expect(attempt.payloadHash, expectedConfirmHash);
    });

    group('gateway error mapping C8', () {
      for (final code in <String>{
        'NOT_FOUND',
        'PERMISSION_DENIED',
        'DATA_SCOPE_DENIED',
        'RETURN_EXCHANGE_BLOCKED',
        'RETURN_QUANTITY_EXCEEDED',
        'STALE_VERSION',
        'PRICE_CHANGED',
        'PRICING_BLOCKED',
        'IDEMPOTENCY_CONFLICT',
        'IMPACT_PENDING',
        'DEPENDENCY_UNAVAILABLE',
      }) {
        test('command gateway preserves stable $code error envelope', () async {
          final gateway = SupabaseReturnExchangeCommandGateway(
            rpcClient: _FakeRpcClient(
              error: RpcException(
                jsonEncode(<String, dynamic>{'code': code, 'message': 'test'}),
              ),
            ),
          );
          await expectLater(
            () => gateway.confirm(
              ConfirmReturnExchangeCommand(
                id: parityCommandId,
                tenantId: parityTenantId,
                actorId: parityActorId,
                returnExchangeId: parityReturnExchangeId,
                idempotencyKey: 'idem',
                payloadHash: 'hash',
                correlationId: parityCorrelationId,
                expectedVersion: 4,
              ),
              referenceDecision: ReturnExchangeReferenceDecision(
                blockers: const [],
                exchangePricingByProductUnitId: const {},
                exchangeProductsByProductUnitId: const {},
                exchangeUnitsByProductUnitId: const {},
                reservationIds: const [],
              ),
            ),
            throwsA(isA<SalesContractException>().having((e) => e.code, 'code', code)),
          );
        });

        test('read gateway preserves stable $code error envelope', () async {
          final gateway = SupabaseReturnExchangeReadGateway(
            rpcClient: _FakeRpcClient(
              error: RpcException(
                jsonEncode(<String, dynamic>{'code': code, 'message': 'test'}),
              ),
            ),
          );
          await expectLater(
            () => gateway.precheck(
              PrecheckReturnExchangeQuery(
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

  group('return exchange rpc parity (new)', () {
    test('params_precheck', () async {
      final rpc = _RecordingRpc()..result = sampleReturnExchangePrecheckJson();
      final repo = ReturnExchangeRepository(
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
      expect(rpc.calls.single.fn, 'precheck_return_exchange');
      expect(rpc.calls.single.params, equals(expectedReturnExchangePrecheckParams()));
      expect(result.allowed, isTrue);
    });

    test('params_returnable', () async {
      final rpc = _RecordingRpc()..result = sampleReturnableOrderLinesJson();
      final repo = ReturnExchangeRepository(
        rpc: rpc,
        tenantId: () async => parityTenantId,
        actorId: () async => parityActorId,
        newId: () => parityQueryId,
      );
      final result = await repo.getReturnableLines(salesOrderId: parityOrderId);
      expect(rpc.calls.single.schema, 'sales');
      expect(rpc.calls.single.fn, 'get_returnable_order_lines');
      expect(rpc.calls.single.params, equals(expectedReturnableParams()));
      expect(result.lines.single.salesOrderLineId, 'line-1');
    });

    test('params_preview', () async {
      final rpc = _RecordingRpc()..result = samplePreviewPricingJson();
      final repo = ReturnExchangeRepository(
        rpc: rpc,
        tenantId: () async => parityTenantId,
        actorId: () async => parityActorId,
        newId: () => parityQueryId,
      );
      final result = await repo.previewPricing(
        salesOrderId: parityOrderId,
        lines: samplePricingLines,
      );
      expect(rpc.calls.single.schema, 'sales');
      expect(rpc.calls.single.fn, 'preview_return_exchange_pricing');
      expect(rpc.calls.single.params, equals(expectedPreviewPricingParams()));
      expect(result.lines.single.productUnitId, 'unit-ex-full');
    });

    test('params_detail', () async {
      final rpc = _RecordingRpc()..result = sampleWrappedDetailJson();
      final repo = ReturnExchangeRepository(
        rpc: rpc,
        tenantId: () async => parityTenantId,
        actorId: () async => parityActorId,
        newId: () => parityQueryId,
      );
      final result = await repo.getDetail(returnExchangeId: parityReturnExchangeId);
      expect(rpc.calls.single.schema, 'sales');
      expect(rpc.calls.single.fn, 'get_return_exchange_detail');
      expect(rpc.calls.single.params, equals(expectedReturnExchangeDetailParams()));
      expect(result.result.returnExchangeId, parityReturnExchangeId);
    });

    test('reference_decision_from_lines', () {
      final decision = ReturnExchangeJson.referenceDecisionFromLines(sampleParityLines);
      expect(decision, equals(expectedReferenceDecision()));
    });

    test('params_start', () async {
      final rpc = _RecordingRpc()..result = sampleDraftJson();
      final repo = ReturnExchangeRepository(
        rpc: rpc,
        tenantId: () async => parityTenantId,
        actorId: () async => parityActorId,
        newId: () => parityCommandId,
      );
      final request = ReturnExchangeStartRequest(
        commandId: parityCommandId,
        salesOrderId: parityOrderId,
        entrySource: ReturnExchangeEntrySource.standard,
        lines: sampleParityLines,
        idempotencyKey: 'return-exchange:start:$parityCommandId',
        payloadHash: expectedStartHash,
        correlationId: parityCorrelationId,
        expectedVersion: 7,
      );
      final result = await repo.start(request);
      expect(rpc.calls.single.schema, 'sales');
      expect(rpc.calls.single.fn, 'start_return_exchange');
      expect(
        rpc.calls.single.params,
        equals(
          expectedStartParams(
            lines: rpc.calls.single.params!['lines'] as List<Map<String, dynamic>>,
            referenceDecision: expectedReferenceDecision(),
          ),
        ),
      );
      expect(result.returnExchangeId, parityReturnExchangeId);
    });

    test('params_update', () async {
      final rpc = _RecordingRpc()..result = sampleDraftJson();
      final repo = ReturnExchangeRepository(
        rpc: rpc,
        tenantId: () async => parityTenantId,
        actorId: () async => parityActorId,
        newId: () => parityCommandId,
      );
      final request = ReturnExchangeUpdateRequest(
        commandId: parityCommandId,
        returnExchangeId: parityReturnExchangeId,
        lines: sampleParityLines,
        idempotencyKey: 'return-exchange:update:$parityCommandId',
        payloadHash: 'hash-update-1',
        correlationId: parityCorrelationId,
        expectedVersion: 3,
      );
      final result = await repo.update(request);
      expect(rpc.calls.single.schema, 'sales');
      expect(rpc.calls.single.fn, 'update_return_exchange');
      expect(
        rpc.calls.single.params,
        equals(
          expectedUpdateParams(
            lines: rpc.calls.single.params!['lines'] as List<Map<String, dynamic>>,
            payloadHash: 'hash-update-1',
            referenceDecision: expectedReferenceDecision(),
          ),
        ),
      );
      expect(result.returnExchangeId, parityReturnExchangeId);
    });

    test('params_cancel', () async {
      final rpc = _RecordingRpc()..result = sampleReturnExchangeResultJson(status: 'cancelled');
      final repo = ReturnExchangeRepository(
        rpc: rpc,
        tenantId: () async => parityTenantId,
        actorId: () async => parityActorId,
        newId: () => parityCommandId,
      );
      final request = const ReturnExchangeMutationRequest(
        commandId: parityCommandId,
        returnExchangeId: parityReturnExchangeId,
        idempotencyKey: 'return-exchange:discard:$parityCommandId',
        payloadHash: 'hash-cancel-1',
        correlationId: parityCorrelationId,
        expectedVersion: 3,
      );
      final result = await repo.cancel(request);
      expect(rpc.calls.single.schema, 'sales');
      expect(rpc.calls.single.fn, 'cancel_return_exchange');
      expect(
        rpc.calls.single.params,
        equals(expectedCancelReturnExchangeParams(payloadHash: 'hash-cancel-1')),
      );
      expect(result.status, ReturnExchangeStatus.cancelled);
    });

    test('params_cancel_null_version', () async {
      final rpc = _RecordingRpc()..result = sampleReturnExchangeResultJson(status: 'cancelled');
      final repo = ReturnExchangeRepository(
        rpc: rpc,
        tenantId: () async => parityTenantId,
        actorId: () async => parityActorId,
        newId: () => parityCommandId,
      );
      final request = const ReturnExchangeMutationRequest(
        commandId: parityCommandId,
        returnExchangeId: parityReturnExchangeId,
        idempotencyKey: 'return-exchange:discard:$parityCommandId',
        payloadHash: 'hash-cancel-1',
        correlationId: parityCorrelationId,
        expectedVersion: null,
      );
      final result = await repo.cancel(request);
      expect(rpc.calls.single.schema, 'sales');
      expect(rpc.calls.single.fn, 'cancel_return_exchange');
      expect(
        rpc.calls.single.params,
        equals(
          expectedCancelReturnExchangeParams(
            payloadHash: 'hash-cancel-1',
            expectedVersion: null,
          ),
        ),
      );
      expect(rpc.calls.single.params!.containsKey('expected_version'), isTrue);
      expect(rpc.calls.single.params!['expected_version'], isNull);
      expect(result.status, ReturnExchangeStatus.cancelled);
    });

    test('params_confirm', () async {
      final rpc = _RecordingRpc()..result = sampleReturnExchangeResultJson();
      final repo = ReturnExchangeRepository(
        rpc: rpc,
        tenantId: () async => parityTenantId,
        actorId: () async => parityActorId,
        newId: () => parityCommandId,
      );
      final request = ReturnExchangeConfirmRequest(
        commandId: parityCommandId,
        returnExchangeId: parityReturnExchangeId,
        idempotencyKey: 'return-exchange:confirm:$parityCommandId',
        payloadHash: expectedConfirmHash,
        correlationId: parityCorrelationId,
        expectedVersion: 4,
        settledNowMinor: 100000,
        paymentMethod: SalesPaymentMethod.cash,
        paymentDueDate: DateTime(2026, 11, 20, 23, 30),
      );
      final result = await repo.confirm(request);
      expect(rpc.calls.single.schema, 'sales');
      expect(rpc.calls.single.fn, 'confirm_return_exchange');
      expect(
        rpc.calls.single.params,
        equals(
          expectedConfirmReturnExchangeParams(
            referenceDecision: const <String, dynamic>{
              'blockers': <Object>[],
              'exchange_products_by_product_unit_id': <String, Object>{},
              'exchange_units_by_product_unit_id': <String, Object>{},
              'exchange_prices_by_product_unit_id': <String, Object>{},
              'pricing_source_version': null,
              'inventory_source_version': null,
            },
          ),
        ),
      );
      expect(rpc.calls.single.params!['payment_due_date'], '2026-11-20');
      expect(result.status, ReturnExchangeStatus.confirmed);
    });

    test('params_evaluate', () async {
      final rpc = _RecordingRpc()..result = sampleValuationJson();
      final repo = ReturnExchangeRepository(
        rpc: rpc,
        tenantId: () async => parityTenantId,
        actorId: () async => parityActorId,
        newId: () => parityQueryId,
      );
      final result = await repo.evaluate(
        returnExchangeId: parityReturnExchangeId,
        expectedSourceVersion: 7,
      );
      expect(rpc.calls.single.schema, 'sales');
      expect(rpc.calls.single.fn, 'evaluate_return_exchange_valuation');
      expect(
        rpc.calls.single.params,
        equals(
          expectedEvaluateParams(
            referenceDecision: const <String, dynamic>{
              'blockers': <Object>[],
              'exchange_products_by_product_unit_id': <String, Object>{},
              'exchange_units_by_product_unit_id': <String, Object>{},
              'exchange_prices_by_product_unit_id': <String, Object>{},
              'pricing_source_version': null,
              'inventory_source_version': null,
            },
          ),
        ),
      );
      expect(result.returnValue.amountMinor, 50000);
    });

    test('parse_precheck', () {
      final precheck = ReturnExchangeJson.precheckFromJson(
        sampleReturnExchangePrecheckJson(allowed: true),
      );
      expect(precheck.allowed, isTrue);
      expect(precheck.sourceVersion, 7);

      final blocked = ReturnExchangeJson.precheckFromJson(
        sampleReturnExchangePrecheckJson(allowed: false),
      );
      expect(blocked.allowed, isFalse);
      expect(blocked.blockers.single.code, 'ORDER_ALREADY_CANCELLED');
    });

    test('parse_returnable', () {
      final returnable = ReturnExchangeJson.returnableFromJson(
        sampleReturnableOrderLinesJson(),
      );
      expect(returnable.salesOrderId, parityOrderId);
      expect(returnable.sourceVersion, 7);
      expect(returnable.lines.single.salesOrderLineId, 'line-1');
    });

    test('parse_preview', () {
      final preview = ReturnExchangeJson.previewPricingFromJson(
        samplePreviewPricingJson(),
      );
      expect(preview.lines.single.productUnitId, 'unit-ex-full');
      expect(preview.lines.single.unitPrice.amountMinor, 60000);
    });

    test('parse_draft', () {
      final draft = ReturnExchangeJson.draftFromJson(sampleDraftJson());
      expect(draft.returnExchangeId, parityReturnExchangeId);
      expect(draft.version, 1);
      expect(draft.status, ReturnExchangeStatus.draft);
      expect(draft.lines.single.kind, ReturnExchangeLineKind.returnLine);
    });

    test('parse_result', () {
      final result = ReturnExchangeJson.resultFromJson(
        sampleReturnExchangeResultJson(),
      );
      expect(result.returnExchangeId, parityReturnExchangeId);
      expect(result.version, 4);
      expect(result.status, ReturnExchangeStatus.confirmed);
    });

    test('parse_valuation', () {
      final valuation = ReturnExchangeJson.valuationFromJson(
        sampleValuationJson(),
      );
      expect(valuation.returnValue.amountMinor, 50000);
      expect(valuation.exchangeValue.amountMinor, 120000);
      expect(valuation.settlementDifference.amountMinor, 70000);
      expect(valuation.settlementPlan.collectAmountMinor, 70000);
    });

    test('parse_detail_wrapped', () {
      final detail = ReturnExchangeJson.detailFromJson(
        sampleWrappedDetailJson(),
      );
      expect(detail.result.returnExchangeId, parityReturnExchangeId);
      expect(detail.result.status, ReturnExchangeStatus.confirmed);
      expect(detail.referenceNumber, 'RE-2026-0001');
      expect(detail.lines.single.kind, ReturnExchangeLineKind.returnLine);
      expect(detail.settlementPlan.netDifferenceMinor, 70000);
    });

    test('parse_detail_live', () {
      final detail = ReturnExchangeJson.detailFromJson(
        sampleLiveDetailJson(),
      );
      expect(detail.result.returnExchangeId, parityReturnExchangeId);
      expect(detail.result.status, ReturnExchangeStatus.confirmed);
      expect(detail.referenceNumber, 'RE-2026-0001');
      expect(detail.lines.single.kind, ReturnExchangeLineKind.returnLine);
      expect(detail.settlementPlan.netDifferenceMinor, 70000);
    });

    test('parse_rejects_unknown_key', () async {
      final rpc = _RecordingRpc()
        ..result = <String, dynamic>{
          ...sampleReturnExchangePrecheckJson(),
          'unexpected': true,
        };
      final repo = ReturnExchangeRepository(
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
