import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_domain/domain.dart';

abstract final class CustomerPriceRuleDetailRpcMapper {
  static Map<String, dynamic> params(GetCustomerPriceRuleDetailQuery query) => {
    'p_tenant_id': query.tenantId,
    'p_rule_id': query.ruleId,
    'p_business_date': _date(query.businessDate),
  };

  static CustomerPriceRuleDetailDto detailFromJson(Map<String, dynamic> json) {
    final customer = _requiredMap(json['customer'], 'customer');
    final product = _requiredMap(json['product_unit'], 'product_unit');
    final price = _money(json['price']);
    final period = _requiredMap(json['effective_period'], 'effective_period');
    final validation = _requiredMap(
      json['validation_outcome'],
      'validation_outcome',
    );
    final referenceHealth = _referenceHealth(
      _requiredMap(json['reference_health'], 'reference_health'),
    );
    final sourceTrace = _sourceTrace(
      _requiredMap(json['source_trace'], 'source_trace'),
    );
    final floorPriceHidden = _requiredBool(validation, 'floor_price_hidden');
    final floorPrice = _optionalMoney(validation['floor_price']);
    if (floorPriceHidden && floorPrice != null) {
      throw const FormatException(
        'Hidden floor price must not include a floor amount.',
      );
    }
    final version = json['version'];
    if (version is! int || version <= 0) {
      throw FormatException('Expected version > 0, got $version.');
    }
    final persistedStatus = _persistedStatus(
      _requiredString(json, 'persisted_status'),
    );
    final disabledAt = _optionalInstant(json['disabled_at']);
    final disabledBy = _optionalString(json['disabled_by'], 'disabled_by');
    final disabledReason = _optionalString(
      json['disabled_reason'],
      'disabled_reason',
    );
    if (persistedStatus == CustomerPriceRuleStatus.disabled &&
        (disabledAt == null || disabledBy == null)) {
      throw const FormatException(
        'Disabled customer price rule requires disabled_at and disabled_by.',
      );
    }

    return CustomerPriceRuleDetailDto(
      id: _requiredString(json, 'id'),
      customer: CustomerRefDto(
        customerId: _requiredString(customer, 'customer_id'),
        displayName: _requiredString(customer, 'display_name'),
        status: _requiredString(customer, 'status'),
      ),
      productUnit: ProductUnitRefDto(
        productId: _requiredString(product, 'product_id'),
        productName: _requiredString(product, 'product_name'),
        productUnitId: _requiredString(product, 'product_unit_id'),
        unitName: _requiredString(product, 'unit_name'),
        sellableStatus: _requiredString(product, 'sellable_status'),
        productReferenceId: _optionalString(
          product['product_reference_id'],
          'product_reference_id',
        ),
        sku: _optionalString(product['sku'], 'sku'),
      ),
      price: price,
      effectivePeriod: EffectivePeriodDto(
        effectiveFrom: _calendarDate(_requiredString(period, 'effective_from')),
        effectiveTo: _optionalCalendarDate(period['effective_to']),
      ),
      ruleType: _ruleType(_requiredString(json, 'rule_type')),
      sourceType: _source(_requiredString(json, 'source_type')),
      persistedStatus: persistedStatus,
      derivedStatus: _derivedStatus(_requiredString(json, 'derived_status')),
      note: _optionalString(json['note'], 'note'),
      validationOutcome: RuleValidationOutcomeDto(
        outcome: _requiredString(validation, 'outcome'),
        warningCodes: _requiredStrings(
          validation['warning_codes'],
          'warning_codes',
        ),
        blockingCodes: _requiredStrings(
          validation['blocking_codes'],
          'blocking_codes',
        ),
        listPrice: _optionalMoney(validation['list_price']),
        floorPrice: floorPrice,
        floorPriceHidden: floorPriceHidden,
      ),
      referenceHealth: referenceHealth,
      sourceTrace: sourceTrace,
      createdBy: _requiredString(json, 'created_by'),
      createdAt: _instant(_requiredString(json, 'created_at')),
      updatedBy: _requiredString(json, 'updated_by'),
      updatedAt: _instant(_requiredString(json, 'updated_at')),
      version: version,
      availableActions: _actions(json['available_actions']),
      disabledAt: disabledAt,
      disabledBy: disabledBy,
      disabledReason: disabledReason,
    );
  }

  static CustomerPriceRuleReferenceHealthDto _referenceHealth(
    Map<String, dynamic> json,
  ) => CustomerPriceRuleReferenceHealthDto(
    customerState: _referenceState(_requiredString(json, 'customer_state')),
    productUnitState: _referenceState(
      _requiredString(json, 'product_unit_state'),
    ),
    priceBandState: _priceBandState(_requiredString(json, 'price_band_state')),
    issueCodes: _requiredStrings(json['issue_codes'], 'issue_codes'),
    usedStoredPriceBandSnapshot: _requiredBool(
      json,
      'used_stored_price_band_snapshot',
    ),
  );

  static CustomerPriceRuleSourceTraceDto _sourceTrace(
    Map<String, dynamic> json,
  ) {
    final hidden = _requiredBool(json, 'hidden');
    final sourceImportId = _optionalString(
      json['source_import_id'],
      'source_import_id',
    );
    final sourceImportRowId = _optionalString(
      json['source_import_row_id'],
      'source_import_row_id',
    );
    final sourceOrderId = _optionalString(
      json['source_order_id'],
      'source_order_id',
    );
    final sourceOrderLineId = _optionalString(
      json['source_order_line_id'],
      'source_order_line_id',
    );
    final sourceMemoryRequestId = _optionalString(
      json['source_memory_request_id'],
      'source_memory_request_id',
    );
    if (hidden &&
        (sourceImportId != null ||
            sourceImportRowId != null ||
            sourceOrderId != null ||
            sourceOrderLineId != null ||
            sourceMemoryRequestId != null)) {
      throw const FormatException(
        'Hidden source trace must not include identifiers.',
      );
    }
    return CustomerPriceRuleSourceTraceDto(
      hidden: hidden,
      sourceImportId: sourceImportId,
      sourceImportRowId: sourceImportRowId,
      sourceOrderId: sourceOrderId,
      sourceOrderLineId: sourceOrderLineId,
      sourceMemoryRequestId: sourceMemoryRequestId,
    );
  }

  static List<String> _actions(Object? value) {
    final actions = _requiredStrings(value, 'available_actions');
    for (final action in actions) {
      switch (action) {
        case CustomerPriceRuleAvailableActions.edit:
        case CustomerPriceRuleAvailableActions.disable:
        case CustomerPriceRuleAvailableActions.reenable:
        case CustomerPriceRuleAvailableActions.history:
          break;
        default:
          throw FormatException('Unknown available action: $action.');
      }
    }
    return actions;
  }

  static MoneyDto _money(Object? value) {
    final map = _requiredMap(value, 'money');
    final amount = map['amount_minor'];
    if (amount is! int) {
      throw const FormatException('Money amount_minor must be an integer.');
    }
    return MoneyDto(
      amountMinor: amount,
      currencyCode: _requiredString(map, 'currency_code'),
    );
  }

  static MoneyDto? _optionalMoney(Object? value) =>
      value == null ? null : _money(value);

  static CustomerPriceRuleDerivedStatus _derivedStatus(String value) =>
      switch (value) {
        'applying' => CustomerPriceRuleDerivedStatus.applying,
        'not_yet_effective' => CustomerPriceRuleDerivedStatus.notYetEffective,
        'disabled' => CustomerPriceRuleDerivedStatus.disabled,
        'expired' => CustomerPriceRuleDerivedStatus.expired,
        'needs_review' => CustomerPriceRuleDerivedStatus.needsReview,
        _ => throw FormatException('Unknown derived status: $value.'),
      };

  static CustomerPriceRuleSourceType _source(String value) => switch (value) {
    'manual' => CustomerPriceRuleSourceType.manual,
    'excel_import' => CustomerPriceRuleSourceType.excelImport,
    'sales_order' => CustomerPriceRuleSourceType.salesOrder,
    'migration' => CustomerPriceRuleSourceType.migration,
    _ => throw FormatException('Unknown rule source: $value.'),
  };

  static CustomerPriceRuleType _ruleType(String value) => switch (value) {
    'special_price' => CustomerPriceRuleType.specialPrice,
    'remembered_price' => CustomerPriceRuleType.rememberedPrice,
    _ => throw FormatException('Unknown rule type: $value.'),
  };

  static CustomerPriceRuleStatus _persistedStatus(String value) =>
      switch (value) {
        'active' => CustomerPriceRuleStatus.active,
        'disabled' => CustomerPriceRuleStatus.disabled,
        'needs_review' => CustomerPriceRuleStatus.needsReview,
        'deleted' => throw const FormatException(
          'Deleted rules must map to NOT_FOUND, not a detail payload.',
        ),
        _ => throw FormatException('Unknown persisted status: $value.'),
      };

  static CustomerPriceRuleReferenceState _referenceState(String value) =>
      switch (value) {
        'valid' => CustomerPriceRuleReferenceState.valid,
        'inactive' => CustomerPriceRuleReferenceState.inactive,
        'missing' => CustomerPriceRuleReferenceState.missing,
        _ => throw FormatException('Unknown reference state: $value.'),
      };

  static CustomerPriceRulePriceBandState _priceBandState(String value) =>
      switch (value) {
        'current' => CustomerPriceRulePriceBandState.current,
        'currency_mismatch' => CustomerPriceRulePriceBandState.currencyMismatch,
        'invalid_minor_units' =>
          CustomerPriceRulePriceBandState.invalidMinorUnits,
        'unavailable' => CustomerPriceRulePriceBandState.unavailable,
        _ => throw FormatException('Unknown price band state: $value.'),
      };

  static DateTime? _optionalCalendarDate(Object? value) {
    if (value == null) return null;
    if (value is! String) {
      throw const FormatException('Calendar date must be a string.');
    }
    return _calendarDate(value);
  }

  static DateTime _calendarDate(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) {
      throw FormatException('Expected an ISO calendar date, got $value.');
    }
    final date = DateTime.utc(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
    if (_date(date) != value) {
      throw FormatException('Invalid ISO calendar date: $value.');
    }
    return date;
  }

  static DateTime _instant(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw FormatException('Invalid timestamp: $value.');
    }
    return parsed.toUtc();
  }

  static DateTime? _optionalInstant(Object? value) {
    if (value == null) return null;
    if (value is! String) {
      throw const FormatException('Timestamp must be a string.');
    }
    return _instant(value);
  }

  static Map<String, dynamic> _requiredMap(Object? value, String field) {
    if (value is! Map) {
      throw FormatException('Expected object field $field.');
    }
    return value.cast<String, dynamic>();
  }

  static String _requiredString(Map<String, dynamic> map, String field) {
    final value = map[field];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Expected required string field $field.');
    }
    return value;
  }

  static String? _optionalString(Object? value, String field) {
    if (value == null) return null;
    if (value is! String) {
      throw FormatException('Expected optional string field $field.');
    }
    return value;
  }

  static bool _requiredBool(Map<String, dynamic> map, String field) {
    final value = map[field];
    if (value is! bool) {
      throw FormatException('Expected required boolean field $field.');
    }
    return value;
  }

  static List<String> _requiredStrings(Object? value, String field) {
    if (value is! List || value.any((item) => item is! String)) {
      throw FormatException('Expected string-list field $field.');
    }
    return value.cast<String>().toList(growable: false);
  }

  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
