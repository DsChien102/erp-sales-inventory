import 'package:test/test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_sales_infrastructure/src/domain/return_exchange_order/return_exchange_rpc_mapper.dart';

void main() {
  group('ReturnExchangeRpcMapper', () {
    test('maps precheck and get-returnable query params', () {
      expect(
        ReturnExchangeRpcMapper.precheckParams(
          PrecheckReturnExchangeQuery(
            id: 'query-1',
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            salesOrderId: 'order-1',
            expectedSourceVersion: 7,
          ),
        ),
        <String, dynamic>{
          'query_id': 'query-1',
          'tenant_id': 'tenant-1',
          'actor_id': 'actor-1',
          'sales_order_id': 'order-1',
          'expected_source_version': 7,
        },
      );

      expect(
        ReturnExchangeRpcMapper.getReturnableParams(
          GetReturnableOrderLinesQuery(
            id: 'query-2',
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            salesOrderId: 'order-1',
            expectedSourceVersion: 7,
          ),
        ),
        <String, dynamic>{
          'query_id': 'query-2',
          'tenant_id': 'tenant-1',
          'actor_id': 'actor-1',
          'sales_order_id': 'order-1',
          'expected_source_version': 7,
        },
      );

      expect(
        ReturnExchangeRpcMapper.formPolicyParams(
          GetReturnExchangeFormPolicyQuery(
            id: 'query-policy',
            tenantId: 'tenant-1',
            actorId: 'actor-1',
          ),
        ),
        <String, dynamic>{
          'query_id': 'query-policy',
          'tenant_id': 'tenant-1',
          'actor_id': 'actor-1',
        },
      );

      expect(
        ReturnExchangeRpcMapper.detailParams(
          GetReturnExchangeDetailQuery(
            id: 'query-detail',
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            returnExchangeId: 'return-1',
            expectedVersion: 4,
          ),
        ),
        <String, dynamic>{
          'query_id': 'query-detail',
          'tenant_id': 'tenant-1',
          'actor_id': 'actor-1',
          'return_exchange_id': 'return-1',
          'expected_version': 4,
        },
      );
    });

    test('maps context, start, update, and cancel params with reference_decision', () {
      expect(
        ReturnExchangeRpcMapper.contextParams(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          returnExchangeId: 'return-1',
        ),
        <String, dynamic>{
          'tenant_id': 'tenant-1',
          'actor_id': 'actor-1',
          'return_exchange_id': 'return-1',
        },
      );

      final start = _startCommand();
      final decision = _decision();
      final startParams = ReturnExchangeRpcMapper.startParams(
        start,
        referenceDecision: decision,
      );
      expect(startParams['sales_order_id'], 'order-1');
      expect(startParams['entry_source'], 'standard');
      expect(startParams['expected_source_version'], 7);
      expect(startParams['reference_decision'], isA<Map<String, dynamic>>());
      expect(
        (startParams['reference_decision'] as Map<String, dynamic>)
            .containsKey('reservation_ids'),
        isFalse,
      );
      expect(startParams.containsKey('tenant_id'), isTrue);
      expect(
        (startParams['reference_decision'] as Map<String, dynamic>).containsKey('tenant_id'),
        isFalse,
      );

      final updateParams = ReturnExchangeRpcMapper.updateParams(
        _updateCommand(),
        referenceDecision: decision,
      );
      expect(updateParams['return_exchange_id'], 'return-1');
      expect(updateParams['expected_version'], 3);
      expect(updateParams['reference_decision'], isA<Map<String, dynamic>>());

      expect(
        ReturnExchangeRpcMapper.cancelParams(_cancelCommand()),
        <String, dynamic>{
          'command_id': 'command-3',
          'tenant_id': 'tenant-1',
          'actor_id': 'actor-1',
          'return_exchange_id': 'return-1',
          'idempotency_key': 'idem-3',
          'payload_hash': 'hash-3',
          'correlation_id': 'corr-3',
          'causation_id': null,
          'expected_version': 3,
        },
      );
    });

    test('start line inputs carry source_exchange_line_id for exchanged-in returns', () {
      final params = ReturnExchangeRpcMapper.startParams(
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
              sourceExchangeLineId: 'ex-line-1',
              reasonCode: 'DAMAGED',
              conditionCode: 'OPENED',
            ),
          ],
          idempotencyKey: 'idem-1',
          payloadHash: 'hash-1',
          correlationId: 'corr-1',
          expectedVersion: 7,
        ),
        referenceDecision: _decision(),
      );
      final line = (params['lines'] as List).single as Map<String, dynamic>;
      expect(line['source_exchange_line_id'], 'ex-line-1');
      expect(line['original_sales_order_line_id'], isNull);
    });

    test('maps exchange reference snapshots to the SQL draft result wire shape', () {
      final referenceDecision = ReturnExchangeRpcMapper.referenceDecisionToJson(
        _decisionWithExchangeSnapshots(),
      );

      expect(
        referenceDecision['exchange_products_by_product_unit_id'],
        <String, dynamic>{
          'unit-x': <String, dynamic>{
            'productId': 'product-x',
            'sku': 'SKU-X',
            'displayName': 'abc',
          },
        },
      );
      expect(
        referenceDecision['exchange_units_by_product_unit_id'],
        <String, dynamic>{
          'unit-x': <String, dynamic>{
            'productUnitId': 'unit-x',
            'unitCode': 'box',
            'unitName': 'lọ',
          },
        },
      );
      expect(
        referenceDecision['exchange_prices_by_product_unit_id'],
        <String, dynamic>{
          'unit-x': <String, dynamic>{
            'amountMinor': 10000,
            'currencyCode': 'VND',
          },
        },
      );

      final roundTripDraft = ReturnExchangeRpcMapper.draftFromJson(<String, dynamic>{
        'returnExchangeId': 'return-1',
        'salesOrderId': 'order-1',
        'version': 1,
        'status': 'draft',
        'lines': <Object?>[
          <String, dynamic>{
            'kind': 'exchangeLine',
            'productId': 'product-x',
            'productUnitId': 'unit-x',
            'quantity': <String, dynamic>{'quantityMicros': QuantityDto.scale},
            'originalSalesOrderLineId': null,
            'reasonCode': null,
            'conditionCode': null,
            'lineSnapshot': <String, dynamic>{
              'product':
                  (referenceDecision['exchange_products_by_product_unit_id']
                      as Map<String, dynamic>)['unit-x'],
              'unit':
                  (referenceDecision['exchange_units_by_product_unit_id']
                      as Map<String, dynamic>)['unit-x'],
              'unitPrice':
                  (referenceDecision['exchange_prices_by_product_unit_id']
                      as Map<String, dynamic>)['unit-x'],
            },
          },
        ],
      });

      final exchangeLine = roundTripDraft.lines.single;
      expect(exchangeLine.exchangeProductSnapshot?.displayName, 'abc');
      expect(exchangeLine.exchangeUnitSnapshot?.unitName, 'lọ');
      expect(exchangeLine.exchangeUnitPrice?.amountMinor, 10000);
    });

    test('reference decision omits retired reservation persistence', () {
      final json = ReturnExchangeRpcMapper.referenceDecisionToJson(_decision());
      expect(json.containsKey('reservation_ids'), isFalse);
      expect(json, contains('exchange_products_by_product_unit_id'));
      expect(json, contains('exchange_units_by_product_unit_id'));
      expect(json, contains('exchange_prices_by_product_unit_id'));
    });

    test('maps confirm and complete params with server-owned reference_decision', () {
      final decision = _decision();
      final confirmParams = ReturnExchangeRpcMapper.confirmParams(
        _confirmCommand(),
        referenceDecision: decision,
      );
      expect(
        confirmParams,
        <String, dynamic>{
          'command_id': 'command-confirm-1',
          'tenant_id': 'tenant-1',
          'actor_id': 'actor-1',
          'return_exchange_id': 'return-1',
          'idempotency_key': 'idem-c',
          'payload_hash': 'hash-c',
          'correlation_id': 'corr-c',
          'causation_id': null,
          'expected_version': 4,
          'reference_decision': ReturnExchangeRpcMapper.referenceDecisionToJson(decision),
          'payment_settled_now_minor': null,
          'payment_method': 'cash',
          'payment_due_date': null,
        },
      );
      expect(
        (confirmParams['reference_decision'] as Map<String, dynamic>).containsKey('tenant_id'),
        isFalse,
      );

      // Partial payment + method + due date serialize to the RPC wire shape.
      final partial = ReturnExchangeRpcMapper.confirmParams(
        ConfirmReturnExchangeCommand(
          id: 'command-confirm-2',
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          returnExchangeId: 'return-1',
          idempotencyKey: 'idem-c2',
          payloadHash: 'hash-c2',
          correlationId: 'corr-c2',
          expectedVersion: 4,
          settledNowMinor: 150000,
          paymentMethod: SalesPaymentMethod.manualBankTransfer,
          paymentDueDate: DateTime(2026, 7, 30, 9, 15),
        ),
        referenceDecision: decision,
      );
      expect(partial['payment_settled_now_minor'], 150000);
      expect(partial['payment_method'], 'manualBankTransfer');
      expect(partial['payment_due_date'], '2026-07-30');

      expect(
        ReturnExchangeRpcMapper.completeParams(_completeCommand()),
        <String, dynamic>{
          'command_id': 'command-complete-1',
          'tenant_id': 'tenant-1',
          'actor_id': 'actor-1',
          'return_exchange_id': 'return-1',
          'idempotency_key': 'idem-d',
          'payload_hash': 'hash-d',
          'correlation_id': 'corr-d',
          'causation_id': null,
          'expected_version': 5,
        },
      );
      expect(
        ReturnExchangeRpcMapper.completeParams(_completeCommand()).containsKey(
          'reference_decision',
        ),
        isFalse,
      );
    });

    test('decodes precheck, returnable lines, draft, result, and context', () {
      final precheck = ReturnExchangeRpcMapper.precheckFromJson(<String, dynamic>{
        'allowed': true,
        'sourceVersion': 7,
        'blockers': <Object?>[],
      });
      expect(precheck.allowed, isTrue);
      expect(precheck.sourceVersion, 7);

      final returnable = ReturnExchangeRpcMapper.returnableFromJson(<String, dynamic>{
        'salesOrderId': 'order-1',
        'sourceVersion': 7,
        'lines': <Map<String, dynamic>>[
          <String, dynamic>{
            'salesOrderLineId': 'line-1',
            'product': <String, dynamic>{
              'productId': 'product-1',
              'sku': 'SKU-1',
              'displayName': 'Product 1',
            },
            'unit': <String, dynamic>{
              'productUnitId': 'unit-1',
              'unitCode': 'BOX',
              'unitName': 'Box',
            },
            'soldQuantity': <String, dynamic>{'quantityMicros': 2000000},
            'returnableQuantity': <String, dynamic>{'quantityMicros': 1000000},
            'originalUnitPrice': <String, dynamic>{
              'amountMinor': 50000,
              'currencyCode': 'VND',
            },
          },
        ],
      });
      expect(returnable.lines.single.salesOrderLineId, 'line-1');
    });

    test('decodes an exchange-source returnable unit (null salesOrderLineId)', () {
      final dto = ReturnExchangeRpcMapper.returnableFromJson(<String, dynamic>{
        'salesOrderId': 'order-1',
        'sourceVersion': 3,
        'lines': <Object?>[
          <String, dynamic>{
            'salesOrderLineId': null,
            'sourceExchangeLineId': 'ex-line-1',
            'product': <String, dynamic>{'productId': 'p-b', 'sku': null, 'displayName': 'B'},
            'unit': <String, dynamic>{'productUnitId': 'u-b', 'unitCode': null, 'unitName': 'lọ'},
            'soldQuantity': <String, dynamic>{'quantityMicros': 1000000},
            'returnableQuantity': <String, dynamic>{'quantityMicros': 1000000},
            'originalUnitPrice': <String, dynamic>{'amountMinor': 1100000, 'currencyCode': 'VND'},
          },
        ],
      });
      final line = dto.lines.single;
      expect(line.salesOrderLineId, isNull);
      expect(line.sourceExchangeLineId, 'ex-line-1');
      expect(line.unitId, 'ex-line-1');
    });

    test('decodes draft, result, and context after returnable line changes', () {
      final draft = ReturnExchangeRpcMapper.draftFromJson(_draftJson());
      expect(draft.status, ReturnExchangeStatus.draft);
      expect(draft.lines.single.kind, ReturnExchangeLineKind.returnLine);

      final result = ReturnExchangeRpcMapper.resultFromJson(<String, dynamic>{
        'returnExchangeId': 'return-1',
        'salesOrderId': 'order-1',
        'version': 4,
        'status': 'cancelled',
      });
      expect(result.status, ReturnExchangeStatus.cancelled);

      final context = ReturnExchangeRpcMapper.contextFromJson(<String, dynamic>{
        'draft': _draftJson(),
        'currencyCode': 'VND',
        'sourceOrderVersion': 7,
        'sourceSettlementVersion': 2,
        'reservationIds': <String>['res-1'],
      });
      expect(context.currencyCode, 'VND');
      expect(context.reservationIds, <String>['res-1']);
      expect(context.sourceSettlementVersion, 2);
    });

    test('decodes exchange line snapshots from context drafts', () {
      final context = ReturnExchangeRpcMapper.contextFromJson(<String, dynamic>{
        'draft': <String, dynamic>{
          'returnExchangeId': 'return-1',
          'salesOrderId': 'order-1',
          'version': 1,
          'status': 'draft',
          'lines': <Object?>[
            <String, dynamic>{
              'kind': 'exchangeLine',
              'productId': 'product-x',
              'productUnitId': 'unit-x',
              'quantity': <String, dynamic>{'quantityMicros': 1000000},
              'originalSalesOrderLineId': null,
              'reasonCode': null,
              'conditionCode': null,
              'lineSnapshot': <String, dynamic>{
                'product': <String, dynamic>{
                  'productId': 'product-x',
                  'sku': 'SKU-X',
                  'displayName': 'Vitamin C',
                },
                'unit': <String, dynamic>{
                  'productUnitId': 'unit-x',
                  'unitCode': null,
                  'unitName': 'Hộp',
                },
                'unitPrice': <String, dynamic>{
                  'amountMinor': 1000,
                  'currencyCode': 'VND',
                },
              },
            },
          ],
        },
        'currencyCode': 'VND',
        'sourceOrderVersion': 7,
        'sourceSettlementVersion': 1,
        'reservationIds': <Object?>[],
      });

      final line = context.draft.lines.single;
      expect(line.exchangeProductSnapshot?.displayName, 'Vitamin C');
      expect(line.exchangeProductSnapshot?.sku, 'SKU-X');
      expect(line.exchangeUnitSnapshot?.unitName, 'Hộp');
      expect(line.exchangeUnitPrice?.amountMinor, 1000);
    });

    test('maps evaluate and settle payment/refund params without tenant override', () {
      final decision = _decision();
      final evaluateParams = ReturnExchangeRpcMapper.evaluateParams(
        EvaluateReturnPricingImpactQuery(
          id: 'query-eval-1',
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          returnExchangeId: 'return-1',
          expectedSourceVersion: 3,
        ),
        referenceDecision: decision,
      );
      expect(evaluateParams['query_id'], 'query-eval-1');
      expect(evaluateParams['return_exchange_id'], 'return-1');
      expect(evaluateParams['expected_source_version'], 3);
      expect(evaluateParams['reference_decision'], isA<Map<String, dynamic>>());
      expect(
        (evaluateParams['reference_decision'] as Map<String, dynamic>)['pricing_source_version'],
        1,
      );
      expect(
        (evaluateParams['reference_decision'] as Map<String, dynamic>).containsKey('tenant_id'),
        isFalse,
      );

      final paymentParams = ReturnExchangeRpcMapper.settlePaymentParams(
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
      expect(paymentParams['operation'], 'collection');
      expect(paymentParams['sales_order_id'], 'order-1');
      expect(paymentParams['amount_minor'], 25000);
      expect(paymentParams['currency_code'], 'VND');
      expect(paymentParams['method'], 'cash');
      expect(paymentParams['reference'], 'ref-pay-1');
      expect(paymentParams['idempotency_key'], 'idem-pay-1');
      expect(paymentParams['payload_hash'], 'hash-pay-1');
      expect(paymentParams['correlation_id'], 'corr-pay-1');
      expect(paymentParams['expected_source_version'], 2);
      expect(paymentParams.containsKey('return_exchange_id'), isFalse);

      final refundParams = ReturnExchangeRpcMapper.settleRefundParams(
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
      expect(refundParams['operation'], 'refund');
      expect(refundParams['return_exchange_id'], 'return-1');
      expect(refundParams['amount_minor'], 15000);
      expect(refundParams['method'], 'manualBankTransfer');
      expect(refundParams['expected_source_version'], 4);
      expect(refundParams.containsKey('sales_order_id'), isFalse);
    });

    test('decodes valuation, payment summary, and settlement result envelopes', () {
      final valuation = ReturnExchangeRpcMapper.valuationFromJson(<String, dynamic>{
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
      });
      expect(valuation.returnValue.amountMinor, 100000);
      expect(valuation.exchangeValue.amountMinor, 40000);
      expect(valuation.settlementDifference.amountMinor, -60000);
      expect(valuation.sourceOrderVersion, 7);
      expect(valuation.pricingSourceVersion, 11);
      expect(valuation.settlementPlan.netDifferenceMinor, -60000);
      expect(valuation.settlementPlan.refundAmountMinor, 60000);

      final policy = ReturnExchangeRpcMapper.formPolicyFromJson(<String, dynamic>{
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
            'sortOrder': 2,
          },
        ],
      });
      expect(policy.reasons.single.code, 'DAMAGED');
      expect(policy.conditions.single.displayName, 'Opened');

      final detail = ReturnExchangeRpcMapper.detailFromJson(<String, dynamic>{
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
        'completionReady': false,
      });
      expect(detail.referenceNumber, 'RE-return-1');
      expect(detail.entrySource, ReturnExchangeEntrySource.standard);
      expect(detail.confirmedAt, isNull);
      expect(detail.completionReady, isFalse);
      expect(detail.settlementPlan.refundAmountMinor, 60000);

      final liveSqlDetail = ReturnExchangeRpcMapper.detailFromJson(<String, dynamic>{
        'returnExchangeId': 'return-1',
        'salesOrderId': 'order-1',
        'referenceNumber': 'RE-return-1',
        'entrySource': 'standard',
        'version': 3,
        'status': 'draft',
        'completionReady': false,
        'createdAt': '2026-08-19T06:14:00.000Z',
        'confirmedAt': '2026-08-19T06:20:00.000Z',
        'completedAt': '2026-08-19T06:25:00.000Z',
        'lines': <Object?>[],
        'valuation': <String, dynamic>{
          'returnValue': <String, dynamic>{'amountMinor': 100000, 'currencyCode': 'VND'},
          'exchangeValue': <String, dynamic>{'amountMinor': 40000, 'currencyCode': 'VND'},
          'netDifference': <String, dynamic>{
            'amountMinor': -60000,
            'currencyCode': 'VND',
          },
          'status': 'calculated',
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
        'impacts': <Object?>[],
      });
      expect(liveSqlDetail.result.status, ReturnExchangeStatus.draft);
      expect(liveSqlDetail.valuation.settlementDifference.amountMinor, -60000);
      expect(liveSqlDetail.settlementPlan.sourceOrderVersion, 7);
      // The live get_return_exchange_detail RPC emits createdAt/confirmedAt/
      // completedAt; the mapper must accept and parse them, not reject them.
      expect(
        liveSqlDetail.createdAt,
        DateTime.utc(2026, 8, 19, 6, 14),
      );
      expect(
        liveSqlDetail.confirmedAt,
        DateTime.utc(2026, 8, 19, 6, 20),
      );
      expect(
        liveSqlDetail.completedAt,
        DateTime.utc(2026, 8, 19, 6, 25),
      );

      final liveSqlDetailWithoutStoredPlan = ReturnExchangeRpcMapper.detailFromJson(
        <String, dynamic>{
          'returnExchangeId': 'return-1',
          'salesOrderId': 'order-1',
          'referenceNumber': 'RE-return-1',
          'entrySource': 'standard',
          'version': 3,
          'status': 'draft',
          'completionReady': false,
          'lines': <Object?>[],
          'valuation': <String, dynamic>{
            'returnValue': <String, dynamic>{'amountMinor': 100000, 'currencyCode': 'VND'},
            'exchangeValue': <String, dynamic>{'amountMinor': 40000, 'currencyCode': 'VND'},
            'netDifference': <String, dynamic>{
              'amountMinor': -60000,
              'currencyCode': 'VND',
            },
            'sourceOrderVersion': 7,
            'pricingSourceVersion': 11,
            'status': 'calculated',
          },
          'settlementPlan': null,
          'impacts': <Object?>[],
        },
      );
      expect(liveSqlDetailWithoutStoredPlan.settlementPlan.refundAmountMinor, 60000);
      expect(liveSqlDetailWithoutStoredPlan.settlementPlan.sourceOrderVersion, 7);
      expect(
        liveSqlDetailWithoutStoredPlan.valuation.settlementPlan.remainderRefundMinor,
        60000,
      );

      final unevaluatedLiveSqlDetail = ReturnExchangeRpcMapper.detailFromJson(
        <String, dynamic>{
          'returnExchangeId': 'return-1',
          'salesOrderId': 'order-1',
          'referenceNumber': 'RE-return-1',
          'entrySource': 'standard',
          'version': 1,
          'status': 'draft',
          'completionReady': false,
          'lines': <Object?>[],
          'valuation': null,
          'settlementPlan': null,
          'impacts': <Object?>[],
        },
      );
      expect(unevaluatedLiveSqlDetail.valuation.returnValue.amountMinor, 0);
      expect(unevaluatedLiveSqlDetail.valuation.exchangeValue.amountMinor, 0);
      expect(unevaluatedLiveSqlDetail.settlementPlan.netDifferenceMinor, 0);
      expect(unevaluatedLiveSqlDetail.settlementPlan.sourceOrderVersion, 1);

      expect(
        () => ReturnExchangeRpcMapper.formPolicyFromJson(<String, dynamic>{
          'reasons': <Object?>[],
          'conditions': <Object?>[],
          'extra': true,
        }),
        throwsFormatException,
      );

      final negative = ReturnExchangeRpcMapper.valuationFromJson(<String, dynamic>{
        'returnValue': <String, dynamic>{'amountMinor': 10000, 'currencyCode': 'VND'},
        'exchangeValue': <String, dynamic>{'amountMinor': 40000, 'currencyCode': 'VND'},
        'settlementDifference': <String, dynamic>{
          'amountMinor': -30000,
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
        'sourceOrderVersion': 2,
        'pricingSourceVersion': null,
      });
      expect(negative.settlementDifference.amountMinor, -30000);
      expect(negative.pricingSourceVersion, isNull);

      final summary = ReturnExchangeRpcMapper.paymentSummaryFromJson(<String, dynamic>{
        'status': 'partiallyPaid',
        'orderTotal': <String, dynamic>{'amountMinor': 100000, 'currencyCode': 'VND'},
        'paidTotal': <String, dynamic>{'amountMinor': 25000, 'currencyCode': 'VND'},
        'outstandingTotal': <String, dynamic>{'amountMinor': 75000, 'currencyCode': 'VND'},
      });
      expect(summary.status, SalesSettlementStatus.partiallyPaid);
      expect(summary.paidTotal.amountMinor, 25000);

      final result = ReturnExchangeRpcMapper.settlementResultFromJson(<String, dynamic>{
        'returnExchangeId': 'return-1',
        'difference': <String, dynamic>{'amountMinor': 15000, 'currencyCode': 'VND'},
        'status': 'partiallyRefunded',
      });
      expect(result.returnExchangeId, 'return-1');
      expect(result.difference.amountMinor, 15000);
      expect(result.status, SalesSettlementStatus.partiallyRefunded);
    });

    test('accepts nullable product sku snapshots from return/exchange reads', () {
      final returnable = ReturnExchangeRpcMapper.returnableFromJson(<String, dynamic>{
        'salesOrderId': 'order-1',
        'sourceVersion': 1,
        'lines': <Object?>[
          <String, dynamic>{
            'salesOrderLineId': 'line-1',
            'product': <String, dynamic>{
              'productId': 'product-1',
              'sku': null,
              'displayName': 'Product 1',
            },
            'unit': <String, dynamic>{
              'productUnitId': 'unit-1',
              'unitCode': null,
              'unitName': 'Box',
            },
            'soldQuantity': <String, dynamic>{'quantityMicros': 1000000},
            'returnableQuantity': <String, dynamic>{'quantityMicros': 1000000},
            'originalUnitPrice': <String, dynamic>{
              'amountMinor': 1,
              'currencyCode': 'VND',
            },
          },
        ],
      });

      expect(returnable.lines.single.product.sku, isNull);
      expect(returnable.lines.single.unit.unitCode, isNull);
    });

    test('rejects unknown fields, blank ids, non-integral values, and bad envelopes', () {
      expect(
        () => ReturnExchangeRpcMapper.valuationFromJson(<String, dynamic>{
          'returnValue': <String, dynamic>{'amountMinor': 1, 'currencyCode': 'VND'},
          'exchangeValue': <String, dynamic>{'amountMinor': 1, 'currencyCode': 'VND'},
          'settlementDifference': <String, dynamic>{
            'amountMinor': 0,
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
          'sourceOrderVersion': 1,
          'extra': true,
        }),
        throwsFormatException,
      );
      expect(
        () => ReturnExchangeRpcMapper.precheckFromJson(<String, dynamic>{
          'allowed': true,
          'sourceVersion': 1,
          'blockers': <Object?>[],
          'extra': true,
        }),
        throwsFormatException,
      );
      expect(
        () => ReturnExchangeRpcMapper.precheckFromJson(<String, dynamic>{
          'allowed': true,
          'sourceVersion': 1.5,
          'blockers': <Object?>[],
        }),
        throwsFormatException,
      );
      expect(
        () => ReturnExchangeRpcMapper.draftFromJson(<String, dynamic>{
          'returnExchangeId': ' ',
          'salesOrderId': 'order-1',
          'version': 1,
          'status': 'draft',
          'lines': <Object?>[],
        }),
        throwsFormatException,
      );
      expect(
        () => ReturnExchangeRpcMapper.draftFromJson(<String, dynamic>{
          'returnExchangeId': 'return-1',
          'salesOrderId': 'order-1',
          'version': 1,
          'status': 'unknown',
          'lines': <Object?>[],
        }),
        throwsFormatException,
      );
      expect(
        () => ReturnExchangeRpcMapper.returnableFromJson(<String, dynamic>{
          'salesOrderId': 'order-1',
          'sourceVersion': 1,
          'lines': <Object?>[
            <String, dynamic>{
              'salesOrderLineId': 'line-1',
              'product': <String, dynamic>{
                'productId': 'product-1',
                'sku': 'SKU-1',
                'displayName': 'Product 1',
              },
              'unit': <String, dynamic>{
                'productUnitId': 'unit-1',
                'unitCode': 'BOX',
                'unitName': 'Box',
              },
              'soldQuantity': <String, dynamic>{'quantityMicros': 1.2},
              'returnableQuantity': <String, dynamic>{'quantityMicros': 1},
              'originalUnitPrice': <String, dynamic>{
                'amountMinor': 1,
                'currencyCode': 'VND',
              },
            },
          ],
        }),
        throwsFormatException,
      );
      expect(
        () => ReturnExchangeRpcMapper.precheckFromJson(<String, dynamic>{
          'allowed': true,
          'sourceVersion': 1,
          'blockers': <Object?>[
            <String, dynamic>{'code': 'X', 'message': 'Y', 'field': 1},
          ],
        }),
        throwsFormatException,
      );
    });

    test('preview pricing params and response', () {
      final params = ReturnExchangeRpcMapper.previewPricingParams(
        PreviewReturnExchangePricingQuery(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-1',
          lines: const [ReturnExchangePricingLineInput(productId: 'p-1', productUnitId: 'u-1')],
        ),
      );
      expect(params, <String, dynamic>{
        'p_tenant_id': 'tenant-1',
        'p_actor_id': 'actor-1',
        'p_sales_order_id': 'order-1',
        'p_lines': [
          {'product_id': 'p-1', 'product_unit_id': 'u-1'},
        ],
      });

      final dto = ReturnExchangeRpcMapper.previewPricingFromJson({
        'lines': [
          {
            'productUnitId': 'u-1',
            'unitPrice': {'amountMinor': 80000, 'currencyCode': 'VND'},
            'sourceCode': 'CUSTOMER_PRIVATE_RULE',
            'warningCodes': <dynamic>[],
          },
        ],
      });
      expect(dto.lines.single.unitPrice.amountMinor, 80000);
      expect(dto.lines.single.sourceCode, 'CUSTOMER_PRIVATE_RULE');
    });
  });
}

StartReturnExchangeCommand _startCommand() => StartReturnExchangeCommand(
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
);

UpdateReturnExchangeCommand _updateCommand() => UpdateReturnExchangeCommand(
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
);

CancelReturnExchangeCommand _cancelCommand() => CancelReturnExchangeCommand(
  id: 'command-3',
  tenantId: 'tenant-1',
  actorId: 'actor-1',
  returnExchangeId: 'return-1',
  idempotencyKey: 'idem-3',
  payloadHash: 'hash-3',
  correlationId: 'corr-3',
  expectedVersion: 3,
);

ConfirmReturnExchangeCommand _confirmCommand() => ConfirmReturnExchangeCommand(
  id: 'command-confirm-1',
  tenantId: 'tenant-1',
  actorId: 'actor-1',
  returnExchangeId: 'return-1',
  idempotencyKey: 'idem-c',
  payloadHash: 'hash-c',
  correlationId: 'corr-c',
  expectedVersion: 4,
);

CompleteReturnExchangeCommand _completeCommand() => CompleteReturnExchangeCommand(
  id: 'command-complete-1',
  tenantId: 'tenant-1',
  actorId: 'actor-1',
  returnExchangeId: 'return-1',
  idempotencyKey: 'idem-d',
  payloadHash: 'hash-d',
  correlationId: 'corr-d',
  expectedVersion: 5,
);

ReturnExchangeReferenceDecision _decision() => ReturnExchangeReferenceDecision(
  blockers: const <SalesBlockerDto>[],
  exchangePricingByProductUnitId: const <String, PricingSnapshotDto>{},
  exchangeProductsByProductUnitId: const <String, ProductSnapshotDto>{},
  exchangeUnitsByProductUnitId: const <String, ProductUnitSnapshotDto>{},
  pricingSourceVersion: 1,
  inventorySourceVersion: 2,
  reservationIds: const <String>['res-1'],
);

ReturnExchangeReferenceDecision _decisionWithExchangeSnapshots() => ReturnExchangeReferenceDecision(
  blockers: const <SalesBlockerDto>[],
  exchangePricingByProductUnitId: <String, PricingSnapshotDto>{
    'unit-x': PricingSnapshotDto(
      unitPrice: const MoneyDto(amountMinor: 10000, currencyCode: 'VND'),
      source: 'catalog',
      pricedAt: DateTime.utc(2026, 8, 17, 8, 18),
      sourceVersion: 3,
    ),
  },
  exchangeProductsByProductUnitId: const <String, ProductSnapshotDto>{
    'unit-x': ProductSnapshotDto(
      productId: 'product-x',
      sku: 'SKU-X',
      displayName: 'abc',
    ),
  },
  exchangeUnitsByProductUnitId: const <String, ProductUnitSnapshotDto>{
    'unit-x': ProductUnitSnapshotDto(
      productUnitId: 'unit-x',
      unitCode: 'box',
      unitName: 'lọ',
    ),
  },
  pricingSourceVersion: 3,
  inventorySourceVersion: 2,
  reservationIds: const <String>['res-1'],
);

Map<String, dynamic> _draftJson() => <String, dynamic>{
  'returnExchangeId': 'return-1',
  'salesOrderId': 'order-1',
  'version': 1,
  'status': 'draft',
  'lines': <Map<String, dynamic>>[
    <String, dynamic>{
      'kind': 'returnLine',
      'productId': 'product-1',
      'productUnitId': 'unit-1',
      'quantity': <String, dynamic>{'quantityMicros': 1000000},
      'originalSalesOrderLineId': 'line-1',
      'reasonCode': 'DAMAGED',
      'conditionCode': 'OPENED',
    },
  ],
};
