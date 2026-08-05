import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_domain/domain.dart';

abstract final class CustomerPriceRuleSearchRpcMapper {
  static Map<String, dynamic> params(SearchCustomerPriceRulesQuery query) => {
    'p_tenant_id': query.tenantId,
    'p_business_date': _date(query.businessDate),
    'p_q': query.q,
    'p_quick_filter': _quickFilterWire(query.quickFilter),
    'p_statuses': query.statuses.isEmpty
        ? null
        : query.statuses.map(_derivedStatusWire).toList(growable: false),
    'p_sources': query.sources.isEmpty
        ? null
        : query.sources.map(_sourceWire).toList(growable: false),
    'p_customer_id': query.customerId,
    'p_product_id': query.productId,
    'p_cursor': query.cursor,
    'p_limit': query.limit,
  };

  static CustomerPriceRuleSearchResultDto resultFromJson(
    Map<String, dynamic> json,
  ) {
    final items = json['items'];
    final hasMore = json['has_more'];
    final nextCursor = json['next_cursor'];
    if (items is! List ||
        hasMore is! bool ||
        (nextCursor != null && nextCursor is! String)) {
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

  static String _quickFilterWire(CustomerPriceRuleQuickFilter value) =>
      switch (value) {
        CustomerPriceRuleQuickFilter.all => 'all',
        CustomerPriceRuleQuickFilter.applying => 'applying',
        CustomerPriceRuleQuickFilter.belowFloor => 'below_floor',
      };

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

  static String _derivedStatusWire(CustomerPriceRuleDerivedStatus value) =>
      switch (value) {
        CustomerPriceRuleDerivedStatus.applying => 'applying',
        CustomerPriceRuleDerivedStatus.notYetEffective => 'not_yet_effective',
        CustomerPriceRuleDerivedStatus.disabled => 'disabled',
        CustomerPriceRuleDerivedStatus.expired => 'expired',
        CustomerPriceRuleDerivedStatus.needsReview => 'needs_review',
        CustomerPriceRuleDerivedStatus.deleted => 'deleted',
      };

  static CustomerPriceRuleSourceType _source(String value) => switch (value) {
    'manual' => CustomerPriceRuleSourceType.manual,
    'excel_import' => CustomerPriceRuleSourceType.excelImport,
    'sales_order' => CustomerPriceRuleSourceType.salesOrder,
    'migration' => CustomerPriceRuleSourceType.migration,
    _ => throw FormatException('Unknown rule source: $value.'),
  };

  static String _sourceWire(CustomerPriceRuleSourceType value) =>
      switch (value) {
        CustomerPriceRuleSourceType.manual => 'manual',
        CustomerPriceRuleSourceType.excelImport => 'excel_import',
        CustomerPriceRuleSourceType.salesOrder => 'sales_order',
        CustomerPriceRuleSourceType.migration => 'migration',
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
