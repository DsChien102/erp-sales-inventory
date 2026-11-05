import '../models.dart';

abstract final class CustomerPriceRuleJson {
  static const _floorSensitiveKeys = {
    'floor_price_snapshot_minor',
    'floor_price_minor',
    'floor_price',
  };

  static CustomerPriceRuleDetailDto detail(Map<String, dynamic> json) {
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
    final deletedAt = _optionalInstant(json['deleted_at']);
    if (persistedStatus == CustomerPriceRuleStatus.disabled &&
        (disabledAt == null || disabledBy == null)) {
      throw const FormatException(
        'Disabled customer price rule requires disabled_at and disabled_by.',
      );
    }
    if (persistedStatus == CustomerPriceRuleStatus.deleted &&
        deletedAt == null) {
      throw const FormatException(
        'Deleted customer price rule requires deleted_at.',
      );
    }
    if (persistedStatus != CustomerPriceRuleStatus.deleted &&
        deletedAt != null) {
      throw const FormatException(
        'Non-deleted customer price rule must not include deleted_at.',
      );
    }

    return CustomerPriceRuleDetailDto(
      id: _requiredString(json, 'id'),
      customer: CustomerRefDto(
        customerId: _requiredString(customer, 'customer_id'),
        displayName: _requiredString(customer, 'display_name'),
        phone: customer['phone'] as String?,
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
      deletedAt: deletedAt,
      updatedByName: _optionalString(json['updated_by_name'], 'updated_by_name'),
      disabledByName: _optionalString(
        json['disabled_by_name'],
        'disabled_by_name',
      ),
    );
  }

  static CustomerPriceRuleSearchResultDto searchResult(
    Map<String, dynamic> json,
  ) {
    final items = json['items'];
    final hasMore = json['has_more'];
    final nextCursor = json['next_cursor'];
    final totalCount = json['total_count'];
    if (items is! List ||
        hasMore is! bool ||
        (nextCursor != null && nextCursor is! String) ||
        totalCount is! int) {
      throw const FormatException('Malformed pricing search page envelope.');
    }

    return CustomerPriceRuleSearchResultDto(
      page: CursorPageDto(
        items: items.map(_item).toList(growable: false),
        nextCursor: nextCursor as String?,
        hasMore: hasMore,
      ),
      availableActions: _requiredStrings(
        json['available_actions'],
        'available_actions',
      ),
      totalCount: totalCount,
    );
  }

  static CursorPageDto<CustomerPriceRuleActivityDto> historyPage(
    Map<String, dynamic> json,
  ) {
    final items = json['items'];
    final hasMore = json['has_more'];
    final nextCursor = json['next_cursor'];
    if (items is! List ||
        hasMore is! bool ||
        (nextCursor != null && nextCursor is! String)) {
      throw const FormatException('Malformed pricing history page envelope.');
    }

    return CursorPageDto(
      items: List.unmodifiable(items.map(_historyItem).toList(growable: false)),
      nextCursor: nextCursor as String?,
      hasMore: hasMore,
    );
  }

  static CreateCustomerPriceRuleResult createResult(Map<String, dynamic> json) {
    final rule = _map(json['rule']);
    return CreateCustomerPriceRuleResult(
      rule: detail(rule),
      warnings: _issues(json['warnings']),
    );
  }

  static CustomerPriceRuleReenablePrecheckDto precheck(
    Map<String, dynamic> json,
  ) {
    final token = _requiredString(json, 'precheck_token');
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(token)) {
      throw const FormatException('Invalid reenable precheck token.');
    }
    final version = json['rule_version'];
    if (version is! int || version <= 0) {
      throw const FormatException('Invalid reenable rule version.');
    }
    final businessDate = _calendarDate(_requiredString(json, 'business_date'));
    final validation = _requiredMap(
      json['validation_outcome'],
      'validation_outcome',
    );
    return CustomerPriceRuleReenablePrecheckDto(
      validationOutcome: _validationOutcome(validation),
      precheckToken: token,
      ruleVersion: version,
      businessDate: businessDate,
    );
  }

  static ResolveApplicableCustomerPriceRuleResultDto resolveResult(
    Map<String, dynamic> json,
  ) {
    final rule = json['rule'];
    if (rule == null) {
      return const ResolveApplicableCustomerPriceRuleResultDto();
    }
    if (rule is! Map) {
      throw const FormatException('Expected rule object or null.');
    }
    final map = rule.cast<String, dynamic>();
    final price = _requiredMap(map['price'], 'price');
    final period = _requiredMap(map['effective_period'], 'effective_period');
    final version = map['version'];
    if (version is! int || version <= 0) {
      throw FormatException('Expected version > 0, got $version.');
    }
    return ResolveApplicableCustomerPriceRuleResultDto(
      rule: ApplicableCustomerPriceRuleDto(
        ruleId: _requiredString(map, 'rule_id'),
        price: MoneyDto(
          amountMinor: _requiredInt(price['amount_minor']),
          currencyCode: _requiredString(price, 'currency_code'),
        ),
        effectivePeriod: EffectivePeriodDto(
          effectiveFrom: _calendarDate(
            _requiredString(period, 'effective_from'),
          ),
          effectiveTo: _optionalCalendarDate(period['effective_to']),
        ),
        sourceType: _source(_requiredString(map, 'source_type')),
        version: version,
      ),
    );
  }

  static CustomerPriceRuleListItemDto _item(Object? value) {
    final rule = _requiredMap(value, 'item');
    final customer = _requiredMap(rule['customer'], 'customer');
    final product = _requiredMap(rule['product_unit'], 'product_unit');
    final price = _money(rule['price']);
    final period = _requiredMap(rule['effective_period'], 'effective_period');
    final validation = _requiredMap(
      rule['validation_outcome'],
      'validation_outcome',
    );
    if (validation['floor_price'] != null) {
      throw const FormatException(
        'Customer price rule list must not expose floor_price.',
      );
    }

    return CustomerPriceRuleListItemDto(
      id: _requiredString(rule, 'id'),
      customer: CustomerRefDto(
        customerId: _requiredString(customer, 'customer_id'),
        displayName: _requiredString(customer, 'display_name'),
        phone: customer['phone'] as String?,
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
      ruleType: _ruleType(_requiredString(rule, 'rule_type')),
      sourceType: _source(_requiredString(rule, 'source_type')),
      persistedStatus: _persistedStatus(
        _requiredString(rule, 'persisted_status'),
      ),
      derivedStatus: _derivedStatus(_requiredString(rule, 'derived_status')),
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
        floorPrice: null,
        floorPriceHidden: _requiredBool(validation, 'floor_price_hidden'),
      ),
      updatedAt: _instant(_requiredString(rule, 'updated_at')),
    );
  }

  static CustomerPriceRuleActivityDto _historyItem(Object? value) {
    final json = _requiredMap(value, 'item');
    final actor = _requiredMap(json['actor'], 'actor');
    final sourceTrace = _requiredMap(json['source_trace'], 'source_trace');
    final sensitiveValuesHidden = _requiredBool(
      json,
      'sensitive_values_hidden',
    );
    final oldValue = _optionalSnapshot(json['old_value'], 'old_value');
    final newValue = _requiredSnapshot(json['new_value'], 'new_value');
    if (sensitiveValuesHidden) {
      _assertNoFloorLeak(oldValue);
      _assertNoFloorLeak(newValue);
    }

    return CustomerPriceRuleActivityDto(
      id: _requiredString(json, 'id'),
      activityType: _activityType(_requiredString(json, 'activity_type')),
      actor: CustomerPriceRuleActivityActorDto(
        actorId: _optionalString(actor['actor_id'], 'actor_id'),
        displayName: _requiredString(actor, 'display_name'),
        isSystemActor: _requiredBool(actor, 'is_system_actor'),
      ),
      sourceType: _source(_requiredString(json, 'source_type')),
      oldValue: oldValue,
      newValue: newValue,
      reason: _optionalString(json['reason'], 'reason'),
      sourceTrace: CustomerPriceRuleActivitySourceTraceDto(
        importId: _optionalString(sourceTrace['import_id'], 'import_id'),
        importRowId: _optionalString(
          sourceTrace['import_row_id'],
          'import_row_id',
        ),
        orderId: _optionalString(sourceTrace['order_id'], 'order_id'),
        orderLineId: _optionalString(
          sourceTrace['order_line_id'],
          'order_line_id',
        ),
        memoryRequestId: _optionalString(
          sourceTrace['memory_request_id'],
          'memory_request_id',
        ),
        soldAt: _optionalInstant(sourceTrace['sold_at']),
      ),
      sensitiveValuesHidden: sensitiveValuesHidden,
      createdAt: _instant(_requiredString(json, 'created_at')),
    );
  }

  static RuleValidationOutcomeDto _validationOutcome(
    Map<String, dynamic> validation,
  ) {
    final outcome = _requiredString(validation, 'outcome');
    if (outcome != 'valid' && outcome != 'warning' && outcome != 'blocked') {
      throw FormatException('Unknown validation outcome: $outcome.');
    }
    final floorPriceHidden = _requiredBool(validation, 'floor_price_hidden');
    final floorPrice = _optionalMoney(validation['floor_price']);
    if (floorPriceHidden && floorPrice != null) {
      throw const FormatException(
        'Hidden floor price must not include a floor amount.',
      );
    }
    return RuleValidationOutcomeDto(
      outcome: outcome,
      warningCodes: _requiredUniqueStrings(
        validation['warning_codes'],
        'warning_codes',
      ),
      blockingCodes: _requiredUniqueStrings(
        validation['blocking_codes'],
        'blocking_codes',
      ),
      listPrice: _optionalMoney(validation['list_price']),
      floorPrice: floorPrice,
      floorPriceHidden: floorPriceHidden,
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

  static List<RuleIssueDto> _issues(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((raw) {
          final issue = raw.cast<String, dynamic>();
          final details = issue['details'];
          return RuleIssueDto(
            code: issue['code'] as String? ?? '',
            field: issue['field'] as String?,
            details: details is Map
                ? details.cast<String, Object?>()
                : const {},
          );
        })
        .toList(growable: false);
  }

  static MoneyDto _money(Object? value) {
    final map = _requiredMap(value, 'money');
    return MoneyDto(
      amountMinor: _requiredInt(map['amount_minor']),
      currencyCode: _requiredString(map, 'currency_code'),
    );
  }

  static MoneyDto? _optionalMoney(Object? value) =>
      value == null ? null : _money(value);

  static int _requiredInt(Object? value) {
    if (value is int) return value;
    if (value is num && value.isFinite && value == value.truncateToDouble()) {
      return value.toInt();
    }
    throw FormatException('Expected an integer minor-unit value, got $value.');
  }

  static CustomerPriceRuleDerivedStatus _derivedStatus(String value) =>
      switch (value) {
        'applying' => CustomerPriceRuleDerivedStatus.applying,
        'not_yet_effective' => CustomerPriceRuleDerivedStatus.notYetEffective,
        'disabled' => CustomerPriceRuleDerivedStatus.disabled,
        'expired' => CustomerPriceRuleDerivedStatus.expired,
        'needs_review' => CustomerPriceRuleDerivedStatus.needsReview,
        'deleted' => CustomerPriceRuleDerivedStatus.deleted,
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
        'deleted' => CustomerPriceRuleStatus.deleted,
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

  static CustomerPriceRuleActivityType _activityType(String value) =>
      switch (value) {
        'created' => CustomerPriceRuleActivityType.created,
        'updated' => CustomerPriceRuleActivityType.updated,
        'disabled' => CustomerPriceRuleActivityType.disabled,
        'reenabled' => CustomerPriceRuleActivityType.reenabled,
        'deleted' => CustomerPriceRuleActivityType.deleted,
        'import_created' => CustomerPriceRuleActivityType.importCreated,
        'import_updated' => CustomerPriceRuleActivityType.importUpdated,
        'memory_created' => CustomerPriceRuleActivityType.memoryCreated,
        'memory_updated' => CustomerPriceRuleActivityType.memoryUpdated,
        _ => throw FormatException('Unknown activity_type: $value'),
      };

  static Map<String, Object?>? _optionalSnapshot(Object? value, String field) {
    if (value == null) return null;
    return _requiredSnapshot(value, field);
  }

  static Map<String, Object?> _requiredSnapshot(Object? value, String field) {
    if (value is! Map) {
      throw FormatException('Expected object for $field.');
    }
    return _deepFreezeMap(value);
  }

  static void _assertNoFloorLeak(Map<String, Object?>? snapshot) {
    if (snapshot == null) return;
    for (final key in _floorSensitiveKeys) {
      if (snapshot.containsKey(key)) {
        throw FormatException(
          'Hidden floor-sensitive key leaked in snapshot: $key',
        );
      }
    }
  }

  static Map<String, Object?> _deepFreezeMap(Map<dynamic, dynamic> value) {
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw const FormatException('Snapshot keys must be strings.');
      }
      result[entry.key as String] = _deepFreezeValue(entry.value);
    }
    return Map.unmodifiable(result);
  }

  static Object? _deepFreezeValue(Object? value) {
    if (value is Map) {
      return _deepFreezeMap(value);
    }
    if (value is List) {
      return List.unmodifiable(
        value.map(_deepFreezeValue).toList(growable: false),
      );
    }
    return value;
  }

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

  static Map<String, dynamic> _map(Object? value) =>
      value is Map ? value.cast<String, dynamic>() : <String, dynamic>{};

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

  static List<String> _requiredUniqueStrings(Object? value, String field) {
    if (value is! List) {
      throw FormatException('Expected list for $field.');
    }
    final strings = <String>[];
    for (final item in value) {
      if (item is! String || item.trim().isEmpty) {
        throw FormatException('Expected non-empty strings in $field.');
      }
      if (strings.contains(item)) {
        throw FormatException('Duplicate issue code in $field: $item.');
      }
      strings.add(item);
    }
    return strings;
  }

  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

