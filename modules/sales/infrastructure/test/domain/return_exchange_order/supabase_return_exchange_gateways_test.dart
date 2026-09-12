import 'dart:convert';

import 'package:test/test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';
import 'package:vet45_sales_infrastructure/src/adapters/unavailable_return_exchange_reference_port.dart';
import 'package:vet45_sales_infrastructure/src/domain/return_exchange_order/supabase_return_exchange_command_gateway.dart';
import 'package:vet45_sales_infrastructure/src/domain/return_exchange_order/supabase_return_exchange_read_gateway.dart';
import 'package:vet45_sales_infrastructure/src/domain/return_exchange_order/supabase_return_exchange_settlement_gateway.dart';

void main() {
  group('SupabaseReturnExchangeReadGateway', () {
    test('uses precheck_return_exchange', () async {
      final rpc = _FakeRpcClient(
        response: <String, dynamic>{
          'allowed': true,
          'sourceVersion': 7,
          'blockers': <Object?>[],
        },
      );
      final gateway = SupabaseReturnExchangeReadGateway(rpcClient: rpc);

      final dto = await gateway.precheck(
        PrecheckReturnExchangeQuery(
          id: 'query-1',
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-1',
          expectedSourceVersion: 7,
        ),
      );

      expect(rpc.lastProcedure, 'precheck_return_exchange');
      expect(rpc.lastParams, containsPair('sales_order_id', 'order-1'));
      expect(rpc.lastParams, containsPair('expected_source_version', 7));
      expect(dto.allowed, isTrue);
    });

    test('uses get_returnable_order_lines', () async {
      final rpc = _FakeRpcClient(
        response: <String, dynamic>{
          'salesOrderId': 'order-1',
          'sourceVersion': 7,
          'lines': <Object?>[],
        },
      );
      final gateway = SupabaseReturnExchangeReadGateway(rpcClient: rpc);

      final dto = await gateway.getReturnableLines(
        GetReturnableOrderLinesQuery(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-1',
        ),
      );

      expect(rpc.lastProcedure, 'get_returnable_order_lines');
      expect(dto.salesOrderId, 'order-1');
    });

    test('uses get_return_exchange_form_policy', () async {
      final rpc = _FakeRpcClient(
        response: <String, dynamic>{
          'reasons': <Map<String, dynamic>>[
            <String, dynamic>{
              'code': 'DAMAGED',
              'displayName': 'Damaged',
              'sortOrder': 1,
            },
          ],
          'conditions': <Map<String, dynamic>>[
            <String, dynamic>{
              'code': 'OPENED',
              'displayName': 'Opened',
              'sortOrder': 1,
            },
          ],
        },
      );
      final gateway = SupabaseReturnExchangeReadGateway(rpcClient: rpc);

      final dto = await gateway.getFormPolicy(
        GetReturnExchangeFormPolicyQuery(
          id: 'query-policy',
          tenantId: 'tenant-1',
          actorId: 'actor-1',
        ),
      );

      expect(rpc.lastProcedure, 'get_return_exchange_form_policy');
      expect(rpc.callCount, 1);
      expect(dto.reasons.single.code, 'DAMAGED');
      expect(dto.conditions.single.code, 'OPENED');
    });

    test('getFormPolicy decodes empty catalogs without inventing fallbacks', () async {
      final rpc = _FakeRpcClient(
        response: <String, dynamic>{
          'reasons': <Object?>[],
          'conditions': <Object?>[],
        },
      );
      final gateway = SupabaseReturnExchangeReadGateway(rpcClient: rpc);

      final dto = await gateway.getFormPolicy(
        GetReturnExchangeFormPolicyQuery(
          id: 'query-policy-empty',
          tenantId: 'tenant-1',
          actorId: 'actor-1',
        ),
      );

      expect(dto.reasons, isEmpty);
      expect(dto.conditions, isEmpty);
    });

    test('uses get_return_exchange_detail', () async {
      final rpc = _FakeRpcClient(
        response: <String, dynamic>{
          'result': <String, dynamic>{
            'returnExchangeId': 'return-1',
            'salesOrderId': 'order-1',
            'version': 3,
            'status': 'draft',
          },
          'referenceNumber': 'RE-return-1',
          'entrySource': 'standard',
          'createdAt': '2026-08-13T00:00:00.000Z',
          'confirmedByActorId': null,
          'confirmedAt': null,
          'completedAt': null,
          'lines': <Object?>[],
          'valuation': <String, dynamic>{
            'returnValue': <String, dynamic>{'amountMinor': 0, 'currencyCode': 'VND'},
            'exchangeValue': <String, dynamic>{'amountMinor': 0, 'currencyCode': 'VND'},
            'settlementDifference': <String, dynamic>{
              'amountMinor': 0,
              'currencyCode': 'VND',
            },
            'settlementPlan': <String, dynamic>{
              'currencyCode': 'VND',
              'netDifferenceMinor': 0,
              'collectAmountMinor': 0,
              'refundAmountMinor': 0,
              'receivableCreateAmountMinor': 0,
              'receivableReverseAmountMinor': 0,
              'processedCollectMinor': 0,
              'processedRefundMinor': 0,
              'pendingReceivableCreateMinor': 0,
              'pendingReceivableReverseMinor': 0,
              'remainderCollectMinor': 0,
              'remainderRefundMinor': 0,
              'sourceOrderVersion': 1,
              'sourceSettlementVersion': 1,
            },
            'sourceOrderVersion': 1,
          },
          'settlementPlan': <String, dynamic>{
            'currencyCode': 'VND',
            'netDifferenceMinor': 0,
            'collectAmountMinor': 0,
            'refundAmountMinor': 0,
            'receivableCreateAmountMinor': 0,
            'receivableReverseAmountMinor': 0,
            'processedCollectMinor': 0,
            'processedRefundMinor': 0,
            'pendingReceivableCreateMinor': 0,
            'pendingReceivableReverseMinor': 0,
            'remainderCollectMinor': 0,
            'remainderRefundMinor': 0,
            'sourceOrderVersion': 1,
            'sourceSettlementVersion': 1,
          },
          'completionReady': false,
        },
      );
      final gateway = SupabaseReturnExchangeReadGateway(rpcClient: rpc);

      final dto = await gateway.getDetail(
        GetReturnExchangeDetailQuery(
          id: 'query-detail',
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          returnExchangeId: 'return-1',
          expectedVersion: 4,
        ),
      );

      expect(rpc.lastProcedure, 'get_return_exchange_detail');
      expect(rpc.lastParams, containsPair('return_exchange_id', 'return-1'));
      expect(rpc.lastParams, containsPair('expected_version', 4));
      expect(rpc.callCount, 1);
      expect(dto.referenceNumber, 'RE-return-1');
      expect(dto.completionReady, isFalse);
    });

    test('uses _get_return_exchange_context', () async {
      final rpc = _FakeRpcClient(
        response: <String, dynamic>{
          'draft': <String, dynamic>{
            'returnExchangeId': 'return-1',
            'salesOrderId': 'order-1',
            'version': 1,
            'status': 'draft',
            'lines': <Object?>[],
          },
          'currencyCode': 'VND',
          'sourceOrderVersion': 7,
          'sourceSettlementVersion': 2,
          'reservationIds': <String>['res-1'],
        },
      );
      final gateway = SupabaseReturnExchangeReadGateway(rpcClient: rpc);

      final context = await gateway.getContext(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        returnExchangeId: 'return-1',
      );

      expect(rpc.lastProcedure, '_get_return_exchange_context');
      expect(rpc.lastParams, containsPair('return_exchange_id', 'return-1'));
      expect(context.reservationIds, <String>['res-1']);
    });

    test('uses evaluate_return_exchange_valuation with reference_decision', () async {
      final rpc = _FakeRpcClient(
        response: <String, dynamic>{
          'returnValue': <String, dynamic>{'amountMinor': 100000, 'currencyCode': 'VND'},
          'exchangeValue': <String, dynamic>{'amountMinor': 40000, 'currencyCode': 'VND'},
          'settlementDifference': <String, dynamic>{
            'amountMinor': -60000,
            'currencyCode': 'VND',
          },
          'settlementPlan': <String, dynamic>{
            'currencyCode': 'VND',
            'netDifferenceMinor': -60000,
            'collectAmountMinor': 0,
            'refundAmountMinor': 60000,
            'receivableCreateAmountMinor': 0,
            'receivableReverseAmountMinor': 0,
            'processedCollectMinor': 0,
            'processedRefundMinor': 0,
            'pendingReceivableCreateMinor': 0,
            'pendingReceivableReverseMinor': 0,
            'remainderCollectMinor': 0,
            'remainderRefundMinor': 60000,
            'sourceOrderVersion': 7,
            'sourceSettlementVersion': 3,
            'pricingSourceVersion': 11,
          },
          'sourceOrderVersion': 7,
          'pricingSourceVersion': 11,
        },
      );
      final gateway = SupabaseReturnExchangeReadGateway(rpcClient: rpc);

      final dto = await gateway.evaluate(
        EvaluateReturnPricingImpactQuery(
          id: 'query-eval-1',
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          returnExchangeId: 'return-1',
          expectedSourceVersion: 3,
        ),
        referenceDecision: ReturnExchangeReferenceDecision(
          blockers: const <SalesBlockerDto>[],
          exchangeProductsByProductUnitId: const <String, ProductSnapshotDto>{},
          exchangeUnitsByProductUnitId: const <String, ProductUnitSnapshotDto>{},
          exchangePricingByProductUnitId: <String, PricingSnapshotDto>{
            'unit-1': PricingSnapshotDto(
              unitPrice: const MoneyDto(amountMinor: 40000, currencyCode: 'VND'),
              source: 'catalog',
              pricedAt: DateTime.utc(2026, 8, 10),
              sourceVersion: 11,
            ),
          },
          pricingSourceVersion: 11,
          inventorySourceVersion: 2,
          reservationIds: const <String>['res-1'],
        ),
      );

      expect(rpc.lastProcedure, 'evaluate_return_exchange_valuation');
      expect(rpc.lastParams, containsPair('query_id', 'query-eval-1'));
      expect(rpc.lastParams, containsPair('return_exchange_id', 'return-1'));
      expect(rpc.lastParams, containsPair('expected_source_version', 3));
      expect(rpc.lastParams, containsPair('reference_decision', isA<Map<String, dynamic>>()));
      expect(
        (rpc.lastParams!['reference_decision'] as Map<String, dynamic>).containsKey('tenant_id'),
        isFalse,
      );
      expect(dto.settlementDifference.amountMinor, -60000);
      expect(dto.pricingSourceVersion, 11);
    });

    test('surfaces read mapper failures for diagnostics', () async {
      final rpc = _FakeRpcClient(response: <String, dynamic>{'unexpected': true});
      final gateway = SupabaseReturnExchangeReadGateway(rpcClient: rpc);

      await expectLater(
        gateway.evaluate(
          EvaluateReturnPricingImpactQuery(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            returnExchangeId: 'return-1',
          ),
          referenceDecision: ReturnExchangeReferenceDecision(
            blockers: const <SalesBlockerDto>[],
            exchangeProductsByProductUnitId: const <String, ProductSnapshotDto>{},
            exchangeUnitsByProductUnitId: const <String, ProductUnitSnapshotDto>{},
            exchangePricingByProductUnitId: const <String, PricingSnapshotDto>{},
            pricingSourceVersion: null,
            inventorySourceVersion: null,
            reservationIds: const <String>[],
          ),
        ),
        throwsA(
          isA<SalesContractException>()
              .having((error) => error.code, 'code', 'DEPENDENCY_UNAVAILABLE')
              .having(
                (error) => error.message,
                'message',
                contains('Return/exchange read mapper failed'),
              )
              .having(
                (error) => error.details['readMessage'],
                'readMessage',
                contains('FormatException'),
              ),
        ),
      );
    });
  });

  group('SupabaseReturnExchangeSettlementGateway', () {
    test('payment calls settle_return_exchange_difference with operation collection', () async {
      final rpc = _FakeRpcClient(
        response: <String, dynamic>{
          'status': 'partiallyPaid',
          'orderTotal': <String, dynamic>{'amountMinor': 100000, 'currencyCode': 'VND'},
          'paidTotal': <String, dynamic>{'amountMinor': 25000, 'currencyCode': 'VND'},
          'outstandingTotal': <String, dynamic>{'amountMinor': 75000, 'currencyCode': 'VND'},
        },
      );
      final gateway = SupabaseReturnExchangeSettlementGateway(rpcClient: rpc);

      final summary = await gateway.recordPayment(
        RecordSalesPaymentCommand(
          id: 'command-pay-1',
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-1',
          method: SalesPaymentMethod.cash,
          amount: const MoneyDto(amountMinor: 25000, currencyCode: 'VND'),
          reference: 'ref-pay-1',
          idempotencyKey: 'idem-pay-1',
          payloadHash: 'hash-pay-1',
          correlationId: 'corr-pay-1',
          expectedVersion: 2,
        ),
      );

      expect(rpc.lastProcedure, 'settle_return_exchange_difference');
      expect(rpc.lastParams, containsPair('operation', 'collection'));
      expect(rpc.lastParams, containsPair('sales_order_id', 'order-1'));
      expect(rpc.lastParams, containsPair('amount_minor', 25000));
      expect(rpc.lastParams, containsPair('method', 'cash'));
      expect(rpc.lastParams, containsPair('reference', 'ref-pay-1'));
      expect(rpc.lastParams, containsPair('idempotency_key', 'idem-pay-1'));
      expect(rpc.lastParams, containsPair('payload_hash', 'hash-pay-1'));
      expect(rpc.lastParams, containsPair('correlation_id', 'corr-pay-1'));
      expect(rpc.lastParams, containsPair('expected_source_version', 2));
      expect(rpc.lastParams!.containsKey('return_exchange_id'), isFalse);
      expect(summary.paidTotal.amountMinor, 25000);
    });

    test('refund calls settle_return_exchange_difference with operation refund', () async {
      final rpc = _FakeRpcClient(
        response: <String, dynamic>{
          'returnExchangeId': 'return-1',
          'difference': <String, dynamic>{'amountMinor': 15000, 'currencyCode': 'VND'},
          'status': 'partiallyRefunded',
        },
      );
      final gateway = SupabaseReturnExchangeSettlementGateway(rpcClient: rpc);

      final result = await gateway.recordRefund(
        RecordSalesRefundCommand(
          id: 'command-refund-1',
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          returnExchangeId: 'return-1',
          method: SalesPaymentMethod.manualBankTransfer,
          amount: const MoneyDto(amountMinor: 15000, currencyCode: 'VND'),
          reference: 'ref-refund-1',
          idempotencyKey: 'idem-refund-1',
          payloadHash: 'hash-refund-1',
          correlationId: 'corr-refund-1',
          expectedVersion: 4,
        ),
      );

      expect(rpc.lastProcedure, 'settle_return_exchange_difference');
      expect(rpc.lastParams, containsPair('operation', 'refund'));
      expect(rpc.lastParams, containsPair('return_exchange_id', 'return-1'));
      expect(rpc.lastParams, containsPair('expected_source_version', 4));
      expect(rpc.lastParams, containsPair('amount_minor', 15000));
      expect(rpc.lastParams, containsPair('method', 'manualBankTransfer'));
      expect(rpc.lastParams, containsPair('reference', 'ref-refund-1'));
      expect(rpc.lastParams!.containsKey('sales_order_id'), isFalse);
      expect(result.difference.amountMinor, 15000);
    });

    for (final code in <String>{
      'RETURN_EXCHANGE_BLOCKED',
      'STALE_VERSION',
      'IDEMPOTENCY_CONFLICT',
      'IMPACT_PENDING',
      'DEPENDENCY_UNAVAILABLE',
    }) {
      test('settlement preserves stable $code error envelopes', () async {
        final rpc = _FakeRpcClient(
          error: RpcException(jsonEncode(<String, dynamic>{'code': code, 'message': 'Safe.'})),
        );
        final gateway = SupabaseReturnExchangeSettlementGateway(rpcClient: rpc);

        await expectLater(
          () => gateway.recordRefund(
            RecordSalesRefundCommand(
              tenantId: 'tenant-1',
              actorId: 'actor-1',
              returnExchangeId: 'return-1',
              method: SalesPaymentMethod.cash,
              amount: const MoneyDto(amountMinor: 1000, currencyCode: 'VND'),
              idempotencyKey: 'idem-1',
              payloadHash: 'hash-1',
              correlationId: 'corr-1',
              expectedVersion: 1,
            ),
          ),
          throwsA(isA<SalesContractException>().having((error) => error.code, 'code', code)),
        );
      });
    }
  });

  group('SupabaseReturnExchangeCommandGateway', () {
    test('uses start_return_exchange with reference_decision', () async {
      final rpc = _FakeRpcClient(response: _draftJson());
      final gateway = SupabaseReturnExchangeCommandGateway(rpcClient: rpc);

      final draft = await gateway.start(
        StartReturnExchangeCommand(
          id: 'command-1',
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-1',
          entrySource: ReturnExchangeEntrySource.standard,
          lines: const [
            ReturnExchangeLineInput(
              kind: ReturnExchangeLineKind.returnLine,
              productId: 'product-1',
              productUnitId: 'unit-1',
              quantity: QuantityDto(quantityMicros: QuantityDto.scale),
              originalSalesOrderLineId: 'line-1',
              reasonCode: 'DAMAGED',
              conditionCode: 'OPENED',
            ),
          ],
          idempotencyKey: 'idem-1',
          payloadHash: 'hash-1',
          correlationId: 'corr-1',
          expectedVersion: 7,
        ),
        referenceDecision: ReturnExchangeReferenceDecision(
          blockers: const <SalesBlockerDto>[],
          exchangeProductsByProductUnitId: const <String, ProductSnapshotDto>{},
          exchangeUnitsByProductUnitId: const <String, ProductUnitSnapshotDto>{},
          exchangePricingByProductUnitId: const <String, PricingSnapshotDto>{},
          reservationIds: const <String>['res-1'],
        ),
      );

      expect(rpc.lastProcedure, 'start_return_exchange');
      expect(rpc.lastParams, containsPair('sales_order_id', 'order-1'));
      expect(rpc.lastParams, containsPair('expected_source_version', 7));
      expect(rpc.lastParams, containsPair('reference_decision', isA<Map<String, dynamic>>()));
      expect(draft.returnExchangeId, 'return-1');
    });

    test('uses update_return_exchange and cancel_return_exchange', () async {
      final rpc = _FakeRpcClient(response: _draftJson(version: 4));
      final gateway = SupabaseReturnExchangeCommandGateway(rpcClient: rpc);

      await gateway.update(
        UpdateReturnExchangeCommand(
          id: 'command-2',
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          returnExchangeId: 'return-1',
          lines: const [
            ReturnExchangeLineInput(
              kind: ReturnExchangeLineKind.returnLine,
              productId: 'product-1',
              productUnitId: 'unit-1',
              quantity: QuantityDto(quantityMicros: QuantityDto.scale),
              originalSalesOrderLineId: 'line-1',
              reasonCode: 'DAMAGED',
              conditionCode: 'OPENED',
            ),
          ],
          idempotencyKey: 'idem-2',
          payloadHash: 'hash-2',
          correlationId: 'corr-2',
          expectedVersion: 3,
        ),
        referenceDecision: ReturnExchangeReferenceDecision(
          blockers: const <SalesBlockerDto>[],
          exchangeProductsByProductUnitId: const <String, ProductSnapshotDto>{},
          exchangeUnitsByProductUnitId: const <String, ProductUnitSnapshotDto>{},
          exchangePricingByProductUnitId: const <String, PricingSnapshotDto>{},
          reservationIds: const <String>['res-2'],
        ),
      );
      expect(rpc.lastProcedure, 'update_return_exchange');
      expect(rpc.lastParams, containsPair('expected_version', 3));

      rpc.response = <String, dynamic>{
        'returnExchangeId': 'return-1',
        'salesOrderId': 'order-1',
        'version': 5,
        'status': 'cancelled',
      };
      final cancelled = await gateway.cancel(
        CancelReturnExchangeCommand(
          id: 'command-3',
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          returnExchangeId: 'return-1',
          idempotencyKey: 'idem-3',
          payloadHash: 'hash-3',
          correlationId: 'corr-3',
          expectedVersion: 4,
        ),
      );
      expect(rpc.lastProcedure, 'cancel_return_exchange');
      expect(cancelled.status, ReturnExchangeStatus.cancelled);
    });

    test('confirm and complete call exact RPCs with frozen result envelopes', () async {
      final rpc = _FakeRpcClient(
        response: <String, dynamic>{
          'returnExchangeId': 'return-1',
          'salesOrderId': 'order-1',
          'version': 6,
          'status': 'completed',
        },
      );
      final gateway = SupabaseReturnExchangeCommandGateway(rpcClient: rpc);
      final decision = ReturnExchangeReferenceDecision(
        blockers: const <SalesBlockerDto>[],
        exchangeProductsByProductUnitId: const <String, ProductSnapshotDto>{},
        exchangeUnitsByProductUnitId: const <String, ProductUnitSnapshotDto>{},
        exchangePricingByProductUnitId: const <String, PricingSnapshotDto>{},
        reservationIds: const <String>['res-3'],
        pricingSourceVersion: 9,
        inventorySourceVersion: 4,
      );

      final confirmed = await gateway.confirm(
        ConfirmReturnExchangeCommand(
          id: 'command-c',
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          returnExchangeId: 'return-1',
          idempotencyKey: 'idem-c',
          payloadHash: 'hash-c',
          correlationId: 'corr-c',
          expectedVersion: 4,
        ),
        referenceDecision: decision,
      );
      expect(rpc.lastProcedure, 'confirm_return_exchange');
      expect(rpc.lastParams, containsPair('expected_version', 4));
      expect(rpc.lastParams, containsPair('return_exchange_id', 'return-1'));
      expect(rpc.lastParams!['reference_decision'], isA<Map<String, dynamic>>());
      expect(
        (rpc.lastParams!['reference_decision'] as Map<String, dynamic>)
            .containsKey('reservation_ids'),
        isFalse,
      );
      expect(confirmed.status, ReturnExchangeStatus.completed);
      expect(confirmed.version, 6);

      rpc.response = <String, dynamic>{
        'returnExchangeId': 'return-1',
        'salesOrderId': 'order-1',
        'version': 7,
        'status': 'completed',
      };
      final completed = await gateway.complete(
        CompleteReturnExchangeCommand(
          id: 'command-d',
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          returnExchangeId: 'return-1',
          idempotencyKey: 'idem-d',
          payloadHash: 'hash-d',
          correlationId: 'corr-d',
          expectedVersion: 6,
        ),
      );
      expect(rpc.lastProcedure, 'complete_return_exchange');
      expect(rpc.lastParams, containsPair('expected_version', 6));
      expect(rpc.lastParams!.containsKey('reference_decision'), isFalse);
      expect(completed.status, ReturnExchangeStatus.completed);
    });

    for (final code in <String>{
      'NOT_FOUND',
      'PERMISSION_DENIED',
      'DATA_SCOPE_DENIED',
      'RETURN_EXCHANGE_BLOCKED',
      'RETURN_QUANTITY_EXCEEDED',
      'STALE_VERSION',
      'IDEMPOTENCY_CONFLICT',
      'IMPACT_PENDING',
      'DEPENDENCY_UNAVAILABLE',
    }) {
      test('preserves stable $code error envelopes', () async {
        final rpc = _FakeRpcClient(
          error: RpcException(jsonEncode(<String, dynamic>{'code': code, 'message': 'Safe.'})),
        );
        final gateway = SupabaseReturnExchangeCommandGateway(rpcClient: rpc);

        await expectLater(
          () => gateway.start(
            StartReturnExchangeCommand(
              tenantId: 'tenant-1',
              actorId: 'actor-1',
              salesOrderId: 'order-1',
              entrySource: ReturnExchangeEntrySource.standard,
              lines: const [],
              idempotencyKey: 'idem-1',
              payloadHash: 'hash-1',
              correlationId: 'corr-1',
              expectedVersion: 1,
            ),
            referenceDecision: ReturnExchangeReferenceDecision(
              blockers: const <SalesBlockerDto>[],
              exchangeProductsByProductUnitId: const <String, ProductSnapshotDto>{},
              exchangeUnitsByProductUnitId: const <String, ProductUnitSnapshotDto>{},
              exchangePricingByProductUnitId: const <String, PricingSnapshotDto>{},
              reservationIds: const <String>[],
            ),
          ),
          throwsA(isA<SalesContractException>().having((error) => error.code, 'code', code)),
        );
      });
    }

    test('maps malformed envelopes to DEPENDENCY_UNAVAILABLE', () async {
      final gateway = SupabaseReturnExchangeCommandGateway(
        rpcClient: _FakeRpcClient(error: RpcException('not-json')),
      );

      await expectLater(
        () => gateway.cancel(
          CancelReturnExchangeCommand(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            returnExchangeId: 'return-1',
            idempotencyKey: 'idem-1',
          ),
        ),
        throwsA(
          isA<SalesContractException>()
              .having(
                (error) => error.code,
                'code',
                'DEPENDENCY_UNAVAILABLE',
              )
              .having(
                (error) => error.details['rpcMessage'],
                'rpcMessage',
                'not-json',
              ),
        ),
      );
    });
  });

  group('UnavailableReturnExchangeReferencePort', () {
    test('evaluate allows deferred reference providers without reservations or pricing', () async {
      final port = UnavailableReturnExchangeReferencePort();
      final decision = await port.evaluate(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        salesOrderId: 'order-1',
        lines: const [],
        reserveExchangeStock: true,
      );

      expect(decision.allowed, isTrue);
      expect(decision.blockers, isEmpty);
      expect(decision.reservationIds, isEmpty);
      expect(decision.exchangePricingByProductUnitId, isEmpty);
      expect(decision.pricingSourceVersion, isNull);
      expect(decision.inventorySourceVersion, isNull);
    });

    test('evaluate carries exchange snapshots from selected exchange lines', () async {
      final port = UnavailableReturnExchangeReferencePort();
      final decision = await port.evaluate(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        salesOrderId: 'order-1',
        lines: const [
          ReturnExchangeLineInput(
            kind: ReturnExchangeLineKind.exchangeLine,
            productId: 'product-x',
            productUnitId: 'unit-x',
            quantity: QuantityDto(quantityMicros: QuantityDto.scale),
            exchangeProductSnapshot: ProductSnapshotDto(
              productId: 'product-x',
              sku: 'SKU-X',
              displayName: 'Vitamin C',
            ),
            exchangeUnitSnapshot: ProductUnitSnapshotDto(
              productUnitId: 'unit-x',
              unitCode: null,
              unitName: 'Hộp',
            ),
            exchangeUnitPrice: MoneyDto(amountMinor: 1000, currencyCode: 'VND'),
          ),
        ],
        reserveExchangeStock: true,
      );

      expect(decision.exchangeProductsByProductUnitId['unit-x']?.displayName, 'Vitamin C');
      expect(decision.exchangeProductsByProductUnitId['unit-x']?.sku, 'SKU-X');
      expect(decision.exchangeUnitsByProductUnitId['unit-x']?.unitName, 'Hộp');
      expect(decision.exchangePricingByProductUnitId['unit-x']?.unitPrice.amountMinor, 1000);
    });

    test('releaseReservations no-ops while reference providers are deferred', () async {
      final port = UnavailableReturnExchangeReferencePort();
      await port.releaseReservations(
        tenantId: 'tenant-1',
        returnExchangeId: 'return-1',
        reservationIds: const <String>[],
        idempotencyKey: 'idem-1',
      );

      await port.releaseReservations(
        tenantId: 'tenant-1',
        returnExchangeId: 'return-1',
        reservationIds: const <String>['res-1'],
        idempotencyKey: 'idem-1',
      );
    });
  });
}

Map<String, dynamic> _draftJson({int version = 1}) => <String, dynamic>{
  'returnExchangeId': 'return-1',
  'salesOrderId': 'order-1',
  'version': version,
  'status': 'draft',
  'lines': <Object?>[],
};

final class _FakeRpcClient implements IRpcClient {
  _FakeRpcClient({this.response = const <String, dynamic>{}, this.error});

  Map<String, dynamic> response;
  final Object? error;
  String? lastProcedure;
  Map<String, dynamic>? lastParams;
  int callCount = 0;

  @override
  Future<Map<String, dynamic>> call(String procedure, {Map<String, dynamic>? params}) async {
    callCount += 1;
    lastProcedure = procedure;
    lastParams = params;
    if (error != null) throw error!;
    return response;
  }
}
