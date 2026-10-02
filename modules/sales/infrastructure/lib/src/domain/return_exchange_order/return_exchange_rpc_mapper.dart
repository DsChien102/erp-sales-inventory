import 'package:vet45_sales_application/application.dart';

/// Maps S28–S31 return/exchange contracts to/from the `sales.*` RPC wire shape.
/// Parameters are snake_case; RPC results use camelCase field names.
abstract final class ReturnExchangeRpcMapper {
  static const _precheckKeys = <String>{'allowed', 'sourceVersion', 'blockers'};

  static const _returnableKeys = <String>{'salesOrderId', 'sourceVersion', 'lines'};

  static const _returnableLineKeys = <String>{
    'salesOrderLineId',
    'sourceExchangeLineId',
    'product',
    'unit',
    'soldQuantity',
    'returnableQuantity',
    'originalUnitPrice',
  };

  static const _productKeys = <String>{'productId', 'sku', 'displayName'};

  // conversionRateToBase is written into product_unit_snapshot at checkout (A2);
  // allow it so return/exchange context and detail snapshots parse (it is ignored here).
  static const _unitKeys = <String>{
    'productUnitId',
    'unitCode',
    'unitName',
    'conversionRateToBase',
  };

  static const _quantityKeys = <String>{'quantityMicros'};

  static const _moneyKeys = <String>{'amountMinor', 'currencyCode'};

  static const _draftKeys = <String>{
    'returnExchangeId',
    'salesOrderId',
    'version',
    'status',
    'lines',
  };

  static const _lineKeys = <String>{
    'kind',
    'productId',
    'productUnitId',
    'quantity',
    'originalSalesOrderLineId',
    'sourceExchangeLineId',
    'reasonCode',
    'conditionCode',
    'lineSnapshot',
  };

  static const _resultKeys = <String>{
    'returnExchangeId',
    'salesOrderId',
    'version',
    'status',
  };

  static const _contextKeys = <String>{
    'draft',
    'currencyCode',
    'sourceOrderVersion',
    'sourceSettlementVersion',
    'reservationIds',
  };

  static const _blockerKeys = <String>{'code', 'message', 'field'};

  static const _valuationKeys = <String>{
    'returnValue',
    'exchangeValue',
    'settlementDifference',
    'settlementPlan',
    'sourceOrderVersion',
    'pricingSourceVersion',
  };

  static const _settlementPlanKeys = <String>{
    'currencyCode',
    'netDifferenceMinor',
    'collectAmountMinor',
    'refundAmountMinor',
    'receivableCreateAmountMinor',
    'receivableReverseAmountMinor',
    'processedCollectMinor',
    'processedRefundMinor',
    'pendingReceivableCreateMinor',
    'pendingReceivableReverseMinor',
    'remainderCollectMinor',
    'remainderRefundMinor',
    'sourceOrderVersion',
    'sourceSettlementVersion',
    'pricingSourceVersion',
  };

  static const _paymentSummaryKeys = <String>{
    'status',
    'orderTotal',
    'paidTotal',
    'refundedTotal',
    'netCollectedTotal',
    'originalPayableTotal',
    'adjustmentTotal',
    'collectedCash',
    'collectedBank',
    'outstandingTotal',
    'dueAt',
    'originalOrder',
    'returnSlips',
  };

  static const _settlementResultKeys = <String>{
    'returnExchangeId',
    'difference',
    'status',
  };

  static const _previewPricingKeys = <String>{'lines'};

  static const _previewPricingLineKeys = <String>{
    'productUnitId',
    'unitPrice',
    'sourceCode',
    'warningCodes',
  };

  static const _formPolicyKeys = <String>{'reasons', 'conditions'};

  static const _policyOptionKeys = <String>{'code', 'displayName', 'sortOrder'};

  static const _detailKeys = <String>{
    'result',
    'referenceNumber',
    'entrySource',
    'createdAt',
    'confirmedByActorId',
    'confirmedAt',
    'completedAt',
    'lines',
    'valuation',
    'settlementPlan',
    'completionReady',
  };

  static const _liveDetailKeys = <String>{
    'returnExchangeId',
    'salesOrderId',
    'referenceNumber',
    'entrySource',
    'version',
    'status',
    'completionReady',
    'createdAt',
    'confirmedAt',
    'completedAt',
    'lines',
    'valuation',
    'settlementPlan',
    'impacts',
  };

  static const _detailValuationKeys = <String>{
    'returnValue',
    'exchangeValue',
    'settlementDifference',
    'netDifference',
    'settlementPlan',
    'sourceOrderVersion',
    'pricingSourceVersion',
    'status',
  };

  static const _detailLineKeys = <String>{
    'lineId',
    'kind',
    'productId',
    'productUnitId',
    'product',
    'unit',
    'quantity',
    'unitPrice',
    'lineTotal',
    'originalSalesOrderLineId',
    'sourceExchangeLineId',
    'reasonCode',
    'conditionCode',
    'lineSnapshot',
  };

  static Map<String, dynamic> precheckParams(PrecheckReturnExchangeQuery query) {
    return <String, dynamic>{
      'query_id': query.id,
      'tenant_id': query.tenantId,
      'actor_id': query.actorId,
      'sales_order_id': query.salesOrderId,
      'expected_source_version': query.expectedSourceVersion,
    };
  }

  static Map<String, dynamic> getReturnableParams(GetReturnableOrderLinesQuery query) {
    return <String, dynamic>{
      'query_id': query.id,
      'tenant_id': query.tenantId,
      'actor_id': query.actorId,
      'sales_order_id': query.salesOrderId,
      'expected_source_version': query.expectedSourceVersion,
    };
  }

  static Map<String, dynamic> previewPricingParams(PreviewReturnExchangePricingQuery query) {
    return <String, dynamic>{
      'p_tenant_id': query.tenantId,
      'p_actor_id': query.actorId,
      'p_sales_order_id': query.salesOrderId,
      'p_lines': [
        for (final line in query.lines)
          <String, dynamic>{'product_id': line.productId, 'product_unit_id': line.productUnitId},
      ],
    };
  }

  static ReturnExchangePricingPreviewDto previewPricingFromJson(Map<String, dynamic> json) {
    _rejectUnknownKeys(json, _previewPricingKeys);
    final lines = json['lines'];
    if (lines is! List) {
      throw const FormatException('Expected lines list.');
    }
    return ReturnExchangePricingPreviewDto(
      lines: [
        for (final line in lines) _previewPricingLineFromJson(line),
      ],
    );
  }

  static ReturnExchangePricedLineDto _previewPricingLineFromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('Expected preview pricing line object.');
    }
    final json = value.cast<String, dynamic>();
    _rejectUnknownKeys(json, _previewPricingLineKeys);
    final warningCodes = json['warningCodes'];
    if (warningCodes is! List) {
      throw const FormatException('Expected warningCodes list.');
    }
    return ReturnExchangePricedLineDto(
      productUnitId: _string(json, 'productUnitId'),
      unitPrice: _moneyFromJson(json['unitPrice']),
      sourceCode: _string(json, 'sourceCode'),
      warningCodes: warningCodes.map((code) => code.toString()).toList(growable: false),
    );
  }

  static Map<String, dynamic> formPolicyParams(GetReturnExchangeFormPolicyQuery query) {
    return <String, dynamic>{
      'query_id': query.id,
      'tenant_id': query.tenantId,
      'actor_id': query.actorId,
    };
  }

  static Map<String, dynamic> detailParams(GetReturnExchangeDetailQuery query) {
    return <String, dynamic>{
      'query_id': query.id,
      'tenant_id': query.tenantId,
      'actor_id': query.actorId,
      'return_exchange_id': query.returnExchangeId,
      'expected_version': query.expectedVersion,
    };
  }

  static Map<String, dynamic> contextParams({
    required String tenantId,
    required String actorId,
    required String returnExchangeId,
  }) {
    return <String, dynamic>{
      'tenant_id': tenantId,
      'actor_id': actorId,
      'return_exchange_id': returnExchangeId,
    };
  }

  static Map<String, dynamic> startParams(
    StartReturnExchangeCommand command, {
    required ReturnExchangeReferenceDecision referenceDecision,
  }) {
    return <String, dynamic>{
      'command_id': command.id,
      'tenant_id': command.tenantId,
      'actor_id': command.actorId,
      'sales_order_id': command.salesOrderId,
      'entry_source': _entrySourceWire(command.entrySource),
      'lines': _lineInputs(command.lines),
      'idempotency_key': command.idempotencyKey,
      'payload_hash': command.payloadHash,
      'correlation_id': command.correlationId,
      'causation_id': command.causationId,
      'expected_source_version': command.expectedVersion,
      'reference_decision': referenceDecisionToJson(referenceDecision),
    };
  }

  static Map<String, dynamic> updateParams(
    UpdateReturnExchangeCommand command, {
    required ReturnExchangeReferenceDecision referenceDecision,
  }) {
    return <String, dynamic>{
      'command_id': command.id,
      'tenant_id': command.tenantId,
      'actor_id': command.actorId,
      'return_exchange_id': command.returnExchangeId,
      'lines': _lineInputs(command.lines),
      'idempotency_key': command.idempotencyKey,
      'payload_hash': command.payloadHash,
      'correlation_id': command.correlationId,
      'causation_id': command.causationId,
      'expected_version': command.expectedVersion,
      'reference_decision': referenceDecisionToJson(referenceDecision),
    };
  }

  static Map<String, dynamic> cancelParams(CancelReturnExchangeCommand command) {
    return <String, dynamic>{
      'command_id': command.id,
      'tenant_id': command.tenantId,
      'actor_id': command.actorId,
      'return_exchange_id': command.returnExchangeId,
      'idempotency_key': command.idempotencyKey,
      'payload_hash': command.payloadHash,
      'correlation_id': command.correlationId,
      'causation_id': command.causationId,
      'expected_version': command.expectedVersion,
    };
  }

  static Map<String, dynamic> confirmParams(
    ConfirmReturnExchangeCommand command, {
    required ReturnExchangeReferenceDecision referenceDecision,
  }) {
    return <String, dynamic>{
      'command_id': command.id,
      'tenant_id': command.tenantId,
      'actor_id': command.actorId,
      'return_exchange_id': command.returnExchangeId,
      'idempotency_key': command.idempotencyKey,
      'payload_hash': command.payloadHash,
      'correlation_id': command.correlationId,
      'causation_id': command.causationId,
      'expected_version': command.expectedVersion,
      'reference_decision': referenceDecisionToJson(referenceDecision),
      'payment_settled_now_minor': command.settledNowMinor,
      'payment_method': _paymentMethodWire(command.paymentMethod),
      'payment_due_date': _dateOnlyWire(command.paymentDueDate),
    };
  }

  static Map<String, dynamic> completeParams(CompleteReturnExchangeCommand command) {
    return <String, dynamic>{
      'command_id': command.id,
      'tenant_id': command.tenantId,
      'actor_id': command.actorId,
      'return_exchange_id': command.returnExchangeId,
      'idempotency_key': command.idempotencyKey,
      'payload_hash': command.payloadHash,
      'correlation_id': command.correlationId,
      'causation_id': command.causationId,
      'expected_version': command.expectedVersion,
    };
  }

  static Map<String, dynamic> evaluateParams(
    EvaluateReturnPricingImpactQuery query, {
    required ReturnExchangeReferenceDecision referenceDecision,
  }) {
    return <String, dynamic>{
      'query_id': query.id,
      'tenant_id': query.tenantId,
      'actor_id': query.actorId,
      'return_exchange_id': query.returnExchangeId,
      'expected_source_version': query.expectedSourceVersion,
      'reference_decision': referenceDecisionToJson(referenceDecision),
    };
  }

  static Map<String, dynamic> settlePaymentParams(RecordSalesPaymentCommand command) {
    return <String, dynamic>{
      'command_id': command.id,
      'tenant_id': command.tenantId,
      'actor_id': command.actorId,
      'operation': 'collection',
      'sales_order_id': command.salesOrderId,
      'amount_minor': command.amount.amountMinor,
      'currency_code': command.amount.currencyCode,
      'method': _paymentMethodWire(command.method),
      'reference': command.reference,
      'idempotency_key': command.idempotencyKey,
      'payload_hash': command.payloadHash,
      'correlation_id': command.correlationId,
      'causation_id': command.causationId,
      'expected_source_version': command.expectedVersion,
    };
  }

  static Map<String, dynamic> settleRefundParams(RecordSalesRefundCommand command) {
    return <String, dynamic>{
      'command_id': command.id,
      'tenant_id': command.tenantId,
      'actor_id': command.actorId,
      'operation': 'refund',
      'return_exchange_id': command.returnExchangeId,
      'amount_minor': command.amount.amountMinor,
      'currency_code': command.amount.currencyCode,
      'method': _paymentMethodWire(command.method),
      'reference': command.reference,
      'idempotency_key': command.idempotencyKey,
      'payload_hash': command.payloadHash,
      'correlation_id': command.correlationId,
      'causation_id': command.causationId,
      'expected_source_version': command.expectedVersion,
    };
  }

  static Map<String, dynamic> referenceDecisionToJson(
    ReturnExchangeReferenceDecision decision,
  ) {
    return <String, dynamic>{
      'blockers': [
        for (final blocker in decision.blockers)
          <String, dynamic>{
            'code': blocker.code,
            'message': blocker.message,
            'field': blocker.field,
          },
      ],
      'exchange_products_by_product_unit_id': {
        for (final entry in decision.exchangeProductsByProductUnitId.entries)
          entry.key: <String, dynamic>{
            'productId': entry.value.productId,
            'sku': entry.value.sku,
            'displayName': entry.value.displayName,
          },
      },
      'exchange_units_by_product_unit_id': {
        for (final entry in decision.exchangeUnitsByProductUnitId.entries)
          entry.key: <String, dynamic>{
            'productUnitId': entry.value.productUnitId,
            'unitCode': entry.value.unitCode,
            'unitName': entry.value.unitName,
          },
      },
      'exchange_prices_by_product_unit_id': {
        for (final entry in decision.exchangePricingByProductUnitId.entries)
          entry.key: <String, dynamic>{
            'amountMinor': entry.value.unitPrice.amountMinor,
            'currencyCode': entry.value.unitPrice.currencyCode,
          },
      },
      'pricing_source_version': decision.pricingSourceVersion,
      'inventory_source_version': decision.inventorySourceVersion,
    };
  }

  static ReturnExchangePrecheckDto precheckFromJson(Map<String, dynamic> json) {
    _rejectUnknownKeys(json, _precheckKeys);
    return ReturnExchangePrecheckDto(
      allowed: _bool(json, 'allowed'),
      sourceVersion: _int(json['sourceVersion']),
      blockers: _blockers(json['blockers']),
    );
  }

  static ReturnableOrderLinesDto returnableFromJson(Map<String, dynamic> json) {
    _rejectUnknownKeys(json, _returnableKeys);
    final lines = json['lines'];
    if (lines is! List) {
      throw const FormatException('Expected lines list.');
    }
    return ReturnableOrderLinesDto(
      salesOrderId: _string(json, 'salesOrderId'),
      sourceVersion: _int(json['sourceVersion']),
      lines: lines.map(_returnableLineFromJson).toList(growable: false),
    );
  }

  static ReturnExchangeDraftDto draftFromJson(Map<String, dynamic> json) {
    _rejectUnknownKeys(json, _draftKeys);
    final lines = json['lines'];
    if (lines is! List) {
      throw const FormatException('Expected lines list.');
    }
    return ReturnExchangeDraftDto(
      returnExchangeId: _string(json, 'returnExchangeId'),
      salesOrderId: _string(json, 'salesOrderId'),
      version: _int(json['version']),
      status: _status(_string(json, 'status')),
      lines: lines.map(_lineFromJson).toList(growable: false),
    );
  }

  static ReturnExchangeResultDto resultFromJson(Map<String, dynamic> json) {
    _rejectUnknownKeys(json, _resultKeys);
    return ReturnExchangeResultDto(
      returnExchangeId: _string(json, 'returnExchangeId'),
      salesOrderId: _string(json, 'salesOrderId'),
      version: _int(json['version']),
      status: _status(_string(json, 'status')),
    );
  }

  static ReturnExchangeContext contextFromJson(Map<String, dynamic> json) {
    _rejectUnknownKeys(json, _contextKeys);
    final draft = json['draft'];
    if (draft is! Map) {
      throw const FormatException('Expected draft object.');
    }
    final reservationIds = json['reservationIds'];
    if (reservationIds is! List) {
      throw const FormatException('Expected reservationIds list.');
    }
    return ReturnExchangeContext(
      draft: draftFromJson(draft.cast<String, dynamic>()),
      currencyCode: _string(json, 'currencyCode'),
      sourceOrderVersion: _int(json['sourceOrderVersion']),
      sourceSettlementVersion: _int(json['sourceSettlementVersion']),
      reservationIds: reservationIds
          .map((item) {
            if (item is! String || item.trim().isEmpty) {
              throw const FormatException('Expected reservation id string.');
            }
            return item;
          })
          .toList(growable: false),
    );
  }

  static ReturnExchangeValuationDto valuationFromJson(Map<String, dynamic> json) {
    _rejectUnknownKeys(json, _valuationKeys);
    return ReturnExchangeValuationDto(
      returnValue: _moneyFromJson(json['returnValue']),
      exchangeValue: _moneyFromJson(json['exchangeValue']),
      settlementDifference: _moneyFromJson(json['settlementDifference']),
      settlementPlan: _settlementPlanFromJson(json['settlementPlan']),
      sourceOrderVersion: _int(json['sourceOrderVersion']),
      pricingSourceVersion: _nullableInt(json['pricingSourceVersion']),
    );
  }

  static ReturnExchangeSettlementPlanDto _settlementPlanFromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('Expected settlementPlan object.');
    }
    final json = value.cast<String, dynamic>();
    _rejectUnknownKeys(json, _settlementPlanKeys);
    return ReturnExchangeSettlementPlanDto(
      currencyCode: _string(json, 'currencyCode'),
      netDifferenceMinor: _int(json['netDifferenceMinor']),
      collectAmountMinor: _int(json['collectAmountMinor']),
      refundAmountMinor: _int(json['refundAmountMinor']),
      receivableCreateAmountMinor: _int(json['receivableCreateAmountMinor']),
      receivableReverseAmountMinor: _int(json['receivableReverseAmountMinor']),
      processedCollectMinor: _int(json['processedCollectMinor']),
      processedRefundMinor: _int(json['processedRefundMinor']),
      pendingReceivableCreateMinor: _int(json['pendingReceivableCreateMinor']),
      pendingReceivableReverseMinor: _int(json['pendingReceivableReverseMinor']),
      remainderCollectMinor: _int(json['remainderCollectMinor']),
      remainderRefundMinor: _int(json['remainderRefundMinor']),
      sourceOrderVersion: _int(json['sourceOrderVersion']),
      sourceSettlementVersion: _int(json['sourceSettlementVersion']),
      pricingSourceVersion: _nullableInt(json['pricingSourceVersion']),
    );
  }

  static SalesOrderPaymentSummaryDto paymentSummaryFromJson(Map<String, dynamic> json) {
    _rejectUnknownKeys(json, _paymentSummaryKeys);
    final originalOrder = json['originalOrder'];
    final returnSlips = json['returnSlips'];
    final originalOrderJson = originalOrder == null
        ? null
        : _requireObject(originalOrder, 'originalOrder');
    return SalesOrderPaymentSummaryDto(
      status: _settlementStatus(_string(json, 'status')),
      orderTotal: _moneyFromJson(json['orderTotal']),
      paidTotal: _moneyFromJson(json['paidTotal']),
      outstandingTotal: _moneyFromJson(json['outstandingTotal']),
      refundedTotal: json['refundedTotal'] == null
          ? null
          : _moneyFromJson(json['refundedTotal']),
      netCollectedTotal: json['netCollectedTotal'] == null
          ? null
          : _moneyFromJson(json['netCollectedTotal']),
      originalPayableTotal: json['originalPayableTotal'] == null
          ? null
          : _moneyFromJson(json['originalPayableTotal']),
      adjustmentTotal: json['adjustmentTotal'] == null
          ? null
          : _moneyFromJson(json['adjustmentTotal']),
      collectedCash: json['collectedCash'] == null
          ? null
          : _moneyFromJson(json['collectedCash']),
      collectedBank: json['collectedBank'] == null
          ? null
          : _moneyFromJson(json['collectedBank']),
      dueAt: _nullableDateTime(json['dueAt']),
      originalOrder: originalOrderJson == null
          ? null
          : SalesOrderPaymentOriginalBreakdownDto(
              orderTotal: _moneyFromJson(originalOrderJson['orderTotal']),
              paidCash: _moneyFromJson(originalOrderJson['paidCash']),
              paidBank: _moneyFromJson(originalOrderJson['paidBank']),
              outstanding: _moneyFromJson(originalOrderJson['outstanding']),
            ),
      returnSlips: returnSlips is! List
          ? const []
          : returnSlips
                .map((item) {
                  final slip = _requireObject(item, 'returnSlip');
                  final paidCashExtra = slip['paidCashExtra'];
                  final paidBankExtra = slip['paidBankExtra'];
                  return SalesOrderPaymentReturnSlipBreakdownDto(
                    slipNumber: _string(slip, 'slipNumber'),
                    customerPaysExtra: _moneyFromJson(slip['customerPaysExtra']),
                    paidCashExtra: paidCashExtra == null ? null : _moneyFromJson(paidCashExtra),
                    paidBankExtra: paidBankExtra == null ? null : _moneyFromJson(paidBankExtra),
                  );
                })
                .toList(growable: false),
    );
  }

  static ReturnExchangeSettlementResultDto settlementResultFromJson(
    Map<String, dynamic> json,
  ) {
    _rejectUnknownKeys(json, _settlementResultKeys);
    return ReturnExchangeSettlementResultDto(
      returnExchangeId: _string(json, 'returnExchangeId'),
      difference: _moneyFromJson(json['difference']),
      status: _settlementStatus(_string(json, 'status')),
    );
  }

  static ReturnExchangeFormPolicyDto formPolicyFromJson(Map<String, dynamic> json) {
    _rejectUnknownKeys(json, _formPolicyKeys);
    final reasons = json['reasons'];
    final conditions = json['conditions'];
    if (reasons is! List || conditions is! List) {
      throw const FormatException('Expected reasons and conditions lists.');
    }
    return ReturnExchangeFormPolicyDto(
      reasons: reasons.map(_policyOptionFromJson).toList(growable: false),
      conditions: conditions.map(_policyOptionFromJson).toList(growable: false),
    );
  }

  static ReturnExchangeDetailDto detailFromJson(Map<String, dynamic> json) {
    if (json['result'] == null) {
      return _liveDetailFromJson(json);
    }

    _rejectUnknownKeys(json, _detailKeys);
    final lines = json['lines'];
    if (lines is! List) {
      throw const FormatException('Expected detail lines list.');
    }
    final result = resultFromJson(_requireObject(json['result'], 'result'));
    final settlementPlan = _detailSettlementPlanFromJson(
      json['settlementPlan'],
      json['valuation'],
      result.version,
    );
    return ReturnExchangeDetailDto(
      result: result,
      referenceNumber: _string(json, 'referenceNumber'),
      entrySource: _nullableEntrySource(json['entrySource']),
      createdAt: _nullableDateTime(json['createdAt']),
      confirmedByActorId: _nullableString(json, 'confirmedByActorId'),
      confirmedAt: _nullableDateTime(json['confirmedAt']),
      completedAt: _nullableDateTime(json['completedAt']),
      lines: lines.map(_detailLineFromJson).toList(growable: false),
      valuation: _detailValuationFromJson(json['valuation'], settlementPlan),
      settlementPlan: settlementPlan,
      completionReady: _bool(json, 'completionReady'),
    );
  }

  static ReturnExchangeDetailDto _liveDetailFromJson(Map<String, dynamic> json) {
    _rejectUnknownKeys(json, _liveDetailKeys);
    final lines = json['lines'];
    if (lines is! List) {
      throw const FormatException('Expected detail lines list.');
    }
    final result = ReturnExchangeResultDto(
      returnExchangeId: _string(json, 'returnExchangeId'),
      salesOrderId: _string(json, 'salesOrderId'),
      version: _int(json['version']),
      status: _status(_string(json, 'status')),
    );
    final settlementPlan = _detailSettlementPlanFromJson(
      json['settlementPlan'],
      json['valuation'],
      result.version,
    );
    return ReturnExchangeDetailDto(
      result: result,
      referenceNumber: _string(json, 'referenceNumber'),
      entrySource: _nullableEntrySource(json['entrySource']),
      createdAt: _nullableDateTime(json['createdAt']),
      // The live get_return_exchange_detail RPC does not surface the actor id.
      confirmedByActorId: null,
      confirmedAt: _nullableDateTime(json['confirmedAt']),
      completedAt: _nullableDateTime(json['completedAt']),
      lines: lines.map(_detailLineFromJson).toList(growable: false),
      valuation: _detailValuationFromJson(json['valuation'], settlementPlan),
      settlementPlan: settlementPlan,
      completionReady: _bool(json, 'completionReady'),
    );
  }

  static ReturnExchangeSettlementPlanDto _detailSettlementPlanFromJson(
    Object? value,
    Object? valuation,
    int fallbackSourceOrderVersion,
  ) {
    if (value is Map) return _settlementPlanFromJson(value);

    if (valuation == null) {
      return ReturnExchangeSettlementPlanDto(
        currencyCode: 'VND',
        netDifferenceMinor: 0,
        collectAmountMinor: 0,
        refundAmountMinor: 0,
        receivableCreateAmountMinor: 0,
        receivableReverseAmountMinor: 0,
        processedCollectMinor: 0,
        processedRefundMinor: 0,
        pendingReceivableCreateMinor: 0,
        pendingReceivableReverseMinor: 0,
        remainderCollectMinor: 0,
        remainderRefundMinor: 0,
        sourceOrderVersion: fallbackSourceOrderVersion,
        sourceSettlementVersion: 0,
      );
    }

    final valuationJson = _requireObject(valuation, 'valuation');
    _rejectUnknownKeys(valuationJson, _detailValuationKeys);
    final difference = _moneyFromJson(
      valuationJson['settlementDifference'] ?? valuationJson['netDifference'],
    );
    final netDifferenceMinor = difference.amountMinor;
    final collectAmountMinor = netDifferenceMinor > 0 ? netDifferenceMinor : 0;
    final refundAmountMinor = netDifferenceMinor < 0 ? -netDifferenceMinor : 0;
    return ReturnExchangeSettlementPlanDto(
      currencyCode: difference.currencyCode,
      netDifferenceMinor: netDifferenceMinor,
      collectAmountMinor: collectAmountMinor,
      refundAmountMinor: refundAmountMinor,
      receivableCreateAmountMinor: 0,
      receivableReverseAmountMinor: 0,
      processedCollectMinor: 0,
      processedRefundMinor: 0,
      pendingReceivableCreateMinor: 0,
      pendingReceivableReverseMinor: 0,
      remainderCollectMinor: collectAmountMinor,
      remainderRefundMinor: refundAmountMinor,
      sourceOrderVersion:
          _nullableInt(valuationJson['sourceOrderVersion']) ?? fallbackSourceOrderVersion,
      sourceSettlementVersion: 0,
      pricingSourceVersion: _nullableInt(valuationJson['pricingSourceVersion']),
    );
  }

  static ReturnExchangeValuationDto _detailValuationFromJson(
    Object? value,
    ReturnExchangeSettlementPlanDto settlementPlan,
  ) {
    if (value == null) {
      final zero = MoneyDto(amountMinor: 0, currencyCode: settlementPlan.currencyCode);
      return ReturnExchangeValuationDto(
        returnValue: zero,
        exchangeValue: zero,
        settlementDifference: zero,
        settlementPlan: settlementPlan,
        sourceOrderVersion: settlementPlan.sourceOrderVersion,
        pricingSourceVersion: settlementPlan.pricingSourceVersion,
      );
    }

    final json = _requireObject(value, 'valuation');
    _rejectUnknownKeys(json, _detailValuationKeys);
    final difference = json['settlementDifference'] ?? json['netDifference'];
    return ReturnExchangeValuationDto(
      returnValue: _moneyFromJson(json['returnValue']),
      exchangeValue: _moneyFromJson(json['exchangeValue']),
      settlementDifference: _moneyFromJson(difference),
      settlementPlan: json['settlementPlan'] == null
          ? settlementPlan
          : _settlementPlanFromJson(json['settlementPlan']),
      sourceOrderVersion:
          _nullableInt(json['sourceOrderVersion']) ?? settlementPlan.sourceOrderVersion,
      pricingSourceVersion:
          _nullableInt(json['pricingSourceVersion']) ?? settlementPlan.pricingSourceVersion,
    );
  }

  static List<Map<String, dynamic>> _lineInputs(List<ReturnExchangeLineInput> lines) {
    return [
      for (final line in lines)
        <String, dynamic>{
          'kind': _lineKindWire(line.kind),
          'product_id': line.productId,
          'product_unit_id': line.productUnitId,
          'quantity_micros': line.quantity.quantityMicros,
          'original_sales_order_line_id': line.originalSalesOrderLineId,
          'source_exchange_line_id': line.sourceExchangeLineId,
          'reason_code': line.reasonCode,
          'condition_code': line.conditionCode,
        },
    ];
  }

  static ReturnableOrderLineDto _returnableLineFromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('Expected returnable line object.');
    }
    final json = value.cast<String, dynamic>();
    _rejectUnknownKeys(json, _returnableLineKeys);
    return ReturnableOrderLineDto(
      salesOrderLineId: _nullableString(json, 'salesOrderLineId'),
      sourceExchangeLineId: _nullableString(json, 'sourceExchangeLineId'),
      product: _productFromJson(json['product']),
      unit: _unitFromJson(json['unit']),
      soldQuantity: _quantityFromJson(json['soldQuantity']),
      returnableQuantity: _quantityFromJson(json['returnableQuantity']),
      originalUnitPrice: _moneyFromJson(json['originalUnitPrice']),
    );
  }

  static ReturnExchangeLineInput _lineFromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('Expected return/exchange line object.');
    }
    final json = value.cast<String, dynamic>();
    _rejectUnknownKeys(json, _lineKeys);
    return ReturnExchangeLineInput(
      kind: _lineKind(_string(json, 'kind')),
      productId: _string(json, 'productId'),
      productUnitId: _string(json, 'productUnitId'),
      quantity: _quantityFromJson(json['quantity']),
      originalSalesOrderLineId: _nullableString(json, 'originalSalesOrderLineId'),
      sourceExchangeLineId: _nullableString(json, 'sourceExchangeLineId'),
      reasonCode: _nullableString(json, 'reasonCode'),
      conditionCode: _nullableString(json, 'conditionCode'),
      exchangeProductSnapshot: _snapshotProduct(json['lineSnapshot']),
      exchangeUnitSnapshot: _snapshotUnit(json['lineSnapshot']),
      exchangeUnitPrice: _snapshotUnitPrice(json['lineSnapshot']),
    );
  }

  static ProductSnapshotDto? _snapshotProduct(Object? value) {
    if (value == null) return null;
    final snapshot = _requireObject(value, 'lineSnapshot');
    final product = snapshot['product'];
    if (product == null) return null;
    return _productFromJson(product);
  }

  static ProductUnitSnapshotDto? _snapshotUnit(Object? value) {
    if (value == null) return null;
    final snapshot = _requireObject(value, 'lineSnapshot');
    final unit = snapshot['unit'];
    if (unit == null) return null;
    return _unitFromJson(unit);
  }

  static MoneyDto? _snapshotUnitPrice(Object? value) {
    if (value == null) return null;
    final snapshot = _requireObject(value, 'lineSnapshot');
    final unitPrice = snapshot['unitPrice'];
    if (unitPrice == null) return null;
    return _moneyFromJson(unitPrice);
  }

  static ProductSnapshotDto _productFromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('Expected product object.');
    }
    final json = value.cast<String, dynamic>();
    _rejectUnknownKeys(json, _productKeys);
    return ProductSnapshotDto(
      productId: _string(json, 'productId'),
      sku: _nullableString(json, 'sku'),
      displayName: _string(json, 'displayName'),
    );
  }

  static ProductUnitSnapshotDto _unitFromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('Expected unit object.');
    }
    final json = value.cast<String, dynamic>();
    _rejectUnknownKeys(json, _unitKeys);
    return ProductUnitSnapshotDto(
      productUnitId: _string(json, 'productUnitId'),
      unitCode: _nullableString(json, 'unitCode'),
      unitName: _string(json, 'unitName'),
    );
  }

  static QuantityDto _quantityFromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('Expected quantity object.');
    }
    final json = value.cast<String, dynamic>();
    _rejectUnknownKeys(json, _quantityKeys);
    return QuantityDto(quantityMicros: _int(json['quantityMicros']));
  }

  static MoneyDto _moneyFromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('Expected money object.');
    }
    final json = value.cast<String, dynamic>();
    _rejectUnknownKeys(json, _moneyKeys);
    return MoneyDto(
      amountMinor: _int(json['amountMinor']),
      currencyCode: _string(json, 'currencyCode'),
    );
  }

  static List<SalesBlockerDto> _blockers(Object? value) {
    if (value is! List) {
      throw const FormatException('Expected blockers list.');
    }
    return value.map(_blockerFromJson).toList(growable: false);
  }

  static SalesBlockerDto _blockerFromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('Expected blocker object.');
    }
    final json = value.cast<String, dynamic>();
    _rejectUnknownKeys(json, _blockerKeys);
    return SalesBlockerDto(
      code: _string(json, 'code'),
      message: _string(json, 'message'),
      field: _nullableString(json, 'field'),
    );
  }

  static ReturnExchangeStatus _status(String value) => switch (value) {
    'draft' => ReturnExchangeStatus.draft,
    'confirmed' => ReturnExchangeStatus.confirmed,
    'processing' => ReturnExchangeStatus.processing,
    'completed' => ReturnExchangeStatus.completed,
    'cancelled' => ReturnExchangeStatus.cancelled,
    'blocked' => ReturnExchangeStatus.blocked,
    'failed' => ReturnExchangeStatus.failed,
    _ => throw FormatException('Unknown return/exchange status: $value.'),
  };

  static ReturnExchangeLineKind _lineKind(String value) => switch (value) {
    'returnLine' => ReturnExchangeLineKind.returnLine,
    'exchangeLine' => ReturnExchangeLineKind.exchangeLine,
    _ => throw FormatException('Unknown return/exchange line kind: $value.'),
  };

  static String _entrySourceWire(ReturnExchangeEntrySource source) => switch (source) {
    ReturnExchangeEntrySource.standard => 'standard',
    ReturnExchangeEntrySource.fullReturnFromCancelAttempt => 'full_return_from_cancel_attempt',
  };

  static String _lineKindWire(ReturnExchangeLineKind kind) => switch (kind) {
    ReturnExchangeLineKind.returnLine => 'returnLine',
    ReturnExchangeLineKind.exchangeLine => 'exchangeLine',
  };

  static String _paymentMethodWire(SalesPaymentMethod method) => switch (method) {
    SalesPaymentMethod.cash => 'cash',
    SalesPaymentMethod.manualBankTransfer => 'manualBankTransfer',
  };

  /// Serializes a due date to the Postgres `date` wire form (`YYYY-MM-DD`),
  /// dropping any time-of-day so it maps cleanly onto a `date` column.
  static String? _dateOnlyWire(DateTime? date) {
    if (date == null) return null;
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static SalesSettlementStatus _settlementStatus(String value) => switch (value) {
    'unpaid' => SalesSettlementStatus.unpaid,
    'partiallyPaid' => SalesSettlementStatus.partiallyPaid,
    'paid' => SalesSettlementStatus.paid,
    'partiallyRefunded' => SalesSettlementStatus.partiallyRefunded,
    'refunded' => SalesSettlementStatus.refunded,
    'no_balance' => SalesSettlementStatus.noBalance,
    _ => throw FormatException('Unknown settlement status: $value.'),
  };

  static ReturnExchangePolicyOptionDto _policyOptionFromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('Expected policy option object.');
    }
    final json = value.cast<String, dynamic>();
    _rejectUnknownKeys(json, _policyOptionKeys);
    return ReturnExchangePolicyOptionDto(
      code: _string(json, 'code'),
      displayName: _string(json, 'displayName'),
      sortOrder: _int(json['sortOrder']),
    );
  }

  static ReturnExchangeDetailLineDto _detailLineFromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('Expected detail line object.');
    }
    final json = value.cast<String, dynamic>();
    _rejectUnknownKeys(json, _detailLineKeys);

    final lineSnapshot = json['lineSnapshot'] is Map
        ? (json['lineSnapshot'] as Map).cast<String, dynamic>()
        : null;
    final productRaw = json['product'] ?? lineSnapshot?['product'];
    final unitRaw = json['unit'] ?? lineSnapshot?['unit'];
    final unitPriceRaw = json['unitPrice'] ?? lineSnapshot?['unitPrice'];

    final product = productRaw != null
        ? _productFromJson(productRaw)
        : ProductSnapshotDto(
            productId: _string(json, 'productId'),
            sku: null,
            displayName: '',
          );

    final unit = unitRaw != null
        ? _unitFromJson(unitRaw)
        : ProductUnitSnapshotDto(
            productUnitId: _string(json, 'productUnitId'),
            unitCode: null,
            unitName: '',
          );

    final quantity = _quantityFromJson(json['quantity']);

    final unitPrice = unitPriceRaw != null
        ? _moneyFromJson(unitPriceRaw)
        : const MoneyDto(amountMinor: 0, currencyCode: 'VND');

    final lineTotal = json['lineTotal'] != null
        ? _moneyFromJson(json['lineTotal'])
        : MoneyDto(
            amountMinor: ((unitPrice.amountMinor * quantity.quantityMicros) /
                    QuantityDto.scale)
                .round(),
            currencyCode: unitPrice.currencyCode,
          );

    return ReturnExchangeDetailLineDto(
      lineId: _nullableString(json, 'lineId'),
      kind: _lineKind(_string(json, 'kind')),
      product: product,
      unit: unit,
      quantity: quantity,
      unitPrice: unitPrice,
      lineTotal: lineTotal,
      originalSalesOrderLineId: _nullableString(json, 'originalSalesOrderLineId'),
      sourceExchangeLineId: _nullableString(json, 'sourceExchangeLineId'),
      reasonCode: _nullableString(json, 'reasonCode'),
      conditionCode: _nullableString(json, 'conditionCode'),
    );
  }

  static Map<String, dynamic> _requireObject(Object? value, String field) {
    if (value is! Map) {
      throw FormatException('Expected $field object.');
    }
    return value.cast<String, dynamic>();
  }

  static ReturnExchangeEntrySource? _nullableEntrySource(Object? value) {
    if (value == null) return null;
    if (value is! String) {
      throw const FormatException('Expected entrySource string.');
    }
    return switch (value) {
      'standard' => ReturnExchangeEntrySource.standard,
      'full_return_from_cancel_attempt' => ReturnExchangeEntrySource.fullReturnFromCancelAttempt,
      _ => throw FormatException('Unknown entrySource: $value.'),
    };
  }

  static DateTime? _nullableDateTime(Object? value) {
    if (value == null) return null;
    if (value is! String || value.trim().isEmpty) {
      throw const FormatException('Expected ISO-8601 datetime string.');
    }
    return DateTime.parse(value).toUtc();
  }

  static void _rejectUnknownKeys(Map<String, dynamic> json, Set<String> allowed) {
    for (final key in json.keys) {
      if (!allowed.contains(key)) {
        throw FormatException('Unexpected field $key.');
      }
    }
  }

  static bool _bool(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is bool) return value;
    throw FormatException('Expected required bool field $key.');
  }

  static String _string(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) return value;
    throw FormatException('Expected required string field $key.');
  }

  static String? _nullableString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null || value is String) return value as String?;
    throw FormatException('Expected nullable string field $key.');
  }

  static int _int(Object? value) {
    if (value is int) return value;
    if (value is num && value.isFinite && value == value.truncateToDouble()) {
      return value.toInt();
    }
    throw FormatException('Expected integer value, got $value.');
  }

  static int? _nullableInt(Object? value) {
    if (value == null) return null;
    return _int(value);
  }
}
