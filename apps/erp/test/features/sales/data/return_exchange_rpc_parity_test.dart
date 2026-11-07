// ignore_for_file: implementation_imports, depend_on_referenced_packages


import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/sales/data/mappers/return_exchange_json.dart';
import 'package:erp/features/sales/data/models/return_exchange_requests.dart';
import 'package:erp/features/sales/data/return_exchange_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_sales_application/application.dart';

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

void main() {
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
