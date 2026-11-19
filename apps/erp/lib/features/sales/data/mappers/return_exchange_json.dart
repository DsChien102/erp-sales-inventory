import 'package:erp/features/sales/data/models/return_exchange_requests.dart';
import 'package:erp/features/sales/data/models.dart';

abstract final class ReturnExchangeJson {
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
    'offsetAmountMinor',
    'offsetCandidates',
  };

  static const _offsetCandidateKeys = <String>{
    'salesOrderId',
    'orderCode',
    'completedAt',
    'outstandingMinor',
    'offsetAmountMinor',
    'dueDate',
    'overdueDays',
    'settlementVersion',
  };

  static const _previewPricingKeys = <String>{'lines'};

  static const _previewPricingLineKeys = <String>{
    'productUnitId',
    'unitPrice',
    'sourceCode',
    'warningCodes',
  };

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

  static const fixedReferenceDecision = <String, dynamic>{
    'blockers': <Object>[],
    'exchange_products_by_product_unit_id': <String, Object>{},
    'exchange_units_by_product_unit_id': <String, Object>{},
    'exchange_prices_by_product_unit_id': <String, Object>{},
    'pricing_source_version': null,
    'inventory_source_version': null,
  };

  static Map<String, dynamic> referenceDecisionFromLines(
    List<ReturnExchangeLineInput> lines,
  ) {
    final exchangeLines = lines.where(
      (line) => line.kind == ReturnExchangeLineKind.exchangeLine,
    );

    final products = <String, dynamic>{};
    final units = <String, dynamic>{};
    final prices = <String, dynamic>{};

    for (final line in exchangeLines) {
      products[line.productUnitId] = <String, dynamic>{
        'productId': line.exchangeProductSnapshot?.productId ?? line.productId,
        'sku': line.exchangeProductSnapshot?.sku,
        'displayName': line.exchangeProductSnapshot?.displayName ?? line.productId,
      };

      units[line.productUnitId] = <String, dynamic>{
        'productUnitId': line.exchangeUnitSnapshot?.productUnitId ?? line.productUnitId,
        'unitCode': line.exchangeUnitSnapshot?.unitCode,
        'unitName': line.exchangeUnitSnapshot?.unitName ?? line.productUnitId,
      };

      prices[line.productUnitId] = <String, dynamic>{
        'amountMinor': line.exchangeUnitPrice?.amountMinor ?? 0,
        'currencyCode': line.exchangeUnitPrice?.currencyCode ?? 'VND',
      };
    }

    return <String, dynamic>{
      'blockers': <Object>[],
      'exchange_products_by_product_unit_id': products,
      'exchange_units_by_product_unit_id': units,
      'exchange_prices_by_product_unit_id': prices,
      'pricing_source_version': null,
      'inventory_source_version': null,
    };
  }

  static Map<String, dynamic> precheckParams({
    required String queryId,
    required String tenantId,
    required String actorId,
    required String salesOrderId,
    required int? expectedSourceVersion,
  }) {
    return <String, dynamic>{
      'query_id': queryId,
      'tenant_id': tenantId,
      'actor_id': actorId,
      'sales_order_id': salesOrderId,
      'expected_source_version': expectedSourceVersion,
    };
  }

  static Map<String, dynamic> returnableParams({
    required String queryId,
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  }) {
    return <String, dynamic>{
      'query_id': queryId,
      'tenant_id': tenantId,
      'actor_id': actorId,
      'sales_order_id': salesOrderId,
      'expected_source_version': null,
    };
  }

  static Map<String, dynamic> previewPricingParams({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
    required List<ReturnExchangePricingLineInput> lines,
  }) {
    return <String, dynamic>{
      'p_tenant_id': tenantId,
      'p_actor_id': actorId,
      'p_sales_order_id': salesOrderId,
      'p_lines': [
        for (final line in lines)
          <String, dynamic>{
            'product_id': line.productId,
            'product_unit_id': line.productUnitId,
          },
      ],
    };
  }

  static Map<String, dynamic> detailParams({
    required String queryId,
    required String tenantId,
    required String actorId,
    required String returnExchangeId,
  }) {
    return <String, dynamic>{
      'query_id': queryId,
      'tenant_id': tenantId,
      'actor_id': actorId,
      'return_exchange_id': returnExchangeId,
      'expected_version': null,
    };
  }

  static Map<String, dynamic> startParams({
    required ReturnExchangeStartRequest request,
    required String tenantId,
    required String actorId,
  }) {
    return <String, dynamic>{
      'command_id': request.commandId,
      'tenant_id': tenantId,
      'actor_id': actorId,
      'sales_order_id': request.salesOrderId,
      'entry_source': _entrySourceWire(request.entrySource),
      'lines': _lineInputs(request.lines),
      'idempotency_key': request.idempotencyKey,
      'payload_hash': request.payloadHash,
      'correlation_id': request.correlationId,
      'causation_id': null,
      'expected_source_version': request.expectedVersion,
      'reference_decision': referenceDecisionFromLines(request.lines),
    };
  }

  static Map<String, dynamic> updateParams({
    required ReturnExchangeUpdateRequest request,
    required String tenantId,
    required String actorId,
  }) {
    return <String, dynamic>{
      'command_id': request.commandId,
      'tenant_id': tenantId,
      'actor_id': actorId,
      'return_exchange_id': request.returnExchangeId,
      'lines': _lineInputs(request.lines),
      'idempotency_key': request.idempotencyKey,
      'payload_hash': request.payloadHash,
      'correlation_id': request.correlationId,
      'causation_id': null,
      'expected_version': request.expectedVersion,
      'reference_decision': referenceDecisionFromLines(request.lines),
    };
  }

  static Map<String, dynamic> cancelParams({
    required ReturnExchangeMutationRequest request,
    required String tenantId,
    required String actorId,
  }) {
    return <String, dynamic>{
      'command_id': request.commandId,
      'tenant_id': tenantId,
      'actor_id': actorId,
      'return_exchange_id': request.returnExchangeId,
      'idempotency_key': request.idempotencyKey,
      'payload_hash': request.payloadHash,
      'correlation_id': request.correlationId,
      'causation_id': null,
      'expected_version': request.expectedVersion,
    };
  }

  static Map<String, dynamic> confirmParams({
    required ReturnExchangeConfirmRequest request,
    required String tenantId,
    required String actorId,
  }) {
    return <String, dynamic>{
      'command_id': request.commandId,
      'tenant_id': tenantId,
      'actor_id': actorId,
      'return_exchange_id': request.returnExchangeId,
      'idempotency_key': request.idempotencyKey,
      'payload_hash': request.payloadHash,
      'correlation_id': request.correlationId,
      'causation_id': null,
      'expected_version': request.expectedVersion,
      'reference_decision': fixedReferenceDecision,
      'payment_settled_now_minor': request.settledNowMinor,
      'payment_method': _paymentMethodWire(request.paymentMethod),
      'payment_due_date': _dateOnlyWire(request.paymentDueDate),
      'offset_target_order_ids': request.offsetTargetOrderIds,
    };
  }

  static Map<String, dynamic> evaluateParams({
    required String queryId,
    required String tenantId,
    required String actorId,
    required String returnExchangeId,
    required int expectedSourceVersion,
  }) {
    return <String, dynamic>{
      'query_id': queryId,
      'tenant_id': tenantId,
      'actor_id': actorId,
      'return_exchange_id': returnExchangeId,
      'expected_source_version': expectedSourceVersion,
      'reference_decision': fixedReferenceDecision,
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

  static ReturnExchangePricingPreviewDto previewPricingFromJson(
    Map<String, dynamic> json,
  ) {
    _rejectUnknownKeys(json, _previewPricingKeys);
    final lines = json['lines'];
    if (lines is! List) {
      throw const FormatException('Expected lines list.');
    }
    return ReturnExchangePricingPreviewDto(
      lines: lines.map(_previewPricingLineFromJson).toList(growable: false),
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

  static ReturnExchangeValuationDto valuationFromJson(
    Map<String, dynamic> json,
  ) {
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

  static ReturnExchangeDetailDto _liveDetailFromJson(
    Map<String, dynamic> json,
  ) {
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
      confirmedByActorId: null,
      confirmedAt: _nullableDateTime(json['confirmedAt']),
      completedAt: _nullableDateTime(json['completedAt']),
      lines: lines.map(_detailLineFromJson).toList(growable: false),
      valuation: _detailValuationFromJson(json['valuation'], settlementPlan),
      settlementPlan: settlementPlan,
      completionReady: _bool(json, 'completionReady'),
    );
  }

  static List<Map<String, dynamic>> _lineInputs(
    List<ReturnExchangeLineInput> lines,
  ) {
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

  static ReturnExchangePricedLineDto _previewPricingLineFromJson(
    Object? value,
  ) {
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
      originalSalesOrderLineId: _nullableString(
        json,
        'originalSalesOrderLineId',
      ),
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

  static ReturnExchangeSettlementPlanDto _settlementPlanFromJson(
    Object? value,
  ) {
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
      pendingReceivableReverseMinor: _int(
        json['pendingReceivableReverseMinor'],
      ),
      remainderCollectMinor: _int(json['remainderCollectMinor']),
      remainderRefundMinor: _int(json['remainderRefundMinor']),
      sourceOrderVersion: _int(json['sourceOrderVersion']),
      sourceSettlementVersion: _int(json['sourceSettlementVersion']),
      pricingSourceVersion: _nullableInt(json['pricingSourceVersion']),
      offsetAmountMinor: _nullableInt(json['offsetAmountMinor']) ?? 0,
      offsetCandidates: _offsetCandidates(json['offsetCandidates']),
    );
  }

  static List<ReturnExchangeOffsetCandidateDto> _offsetCandidates(
    Object? value,
  ) {
    if (value == null) return const [];
    if (value is! List) {
      throw const FormatException('Expected offsetCandidates array.');
    }
    return value.map((item) {
      if (item is! Map) {
        throw const FormatException('Expected offset candidate object.');
      }
      final json = item.cast<String, dynamic>();
      _rejectUnknownKeys(json, _offsetCandidateKeys);
      final due = json['dueDate'];
      DateTime? dueDate;
      if (due != null) {
        if (due is! String) {
          throw const FormatException('Expected dueDate string.');
        }
        final parsed = DateTime.parse(due);
        dueDate = DateTime(parsed.year, parsed.month, parsed.day);
      }
      return ReturnExchangeOffsetCandidateDto(
        salesOrderId: _string(json, 'salesOrderId'),
        orderCode: _string(json, 'orderCode'),
        completedAt: DateTime.parse(_string(json, 'completedAt')).toUtc(),
        outstandingMinor: _int(json['outstandingMinor']),
        offsetAmountMinor: _int(json['offsetAmountMinor']),
        dueDate: dueDate,
        overdueDays: _int(json['overdueDays']),
        settlementVersion: _int(json['settlementVersion']),
      );
    }).toList(growable: false);
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
      final zero = MoneyDto(
        amountMinor: 0,
        currencyCode: settlementPlan.currencyCode,
      );
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
    SalesPaymentMethod.offset =>
      throw ArgumentError('offset is never sent by the app'),
  };

  static String? _dateOnlyWire(DateTime? date) {
    if (date == null) return null;
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
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
            amountMinor: ((unitPrice.amountMinor * quantity.quantityMicros) / QuantityDto.scale)
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
      originalSalesOrderLineId: _nullableString(
        json,
        'originalSalesOrderLineId',
      ),
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

  static void _rejectUnknownKeys(
    Map<String, dynamic> json,
    Set<String> allowed,
  ) {
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
