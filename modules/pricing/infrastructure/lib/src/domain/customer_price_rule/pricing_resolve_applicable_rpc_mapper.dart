import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_domain/domain.dart';

abstract final class PricingResolveApplicableRpcMapper {
  static Map<String, dynamic> params(
    ResolveApplicableCustomerPriceRuleQuery query,
  ) => {
    'p_tenant_id': query.tenantId,
    'p_customer_id': query.customerId.trim(),
    'p_product_id': query.productId.trim(),
    'p_product_unit_id': query.productUnitId.trim(),
    'p_business_date': _date(query.businessDate),
  };

  static ResolveApplicableCustomerPriceRuleResultDto resultFromJson(
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
          amountMinor: _requiredInt(price, 'amount_minor'),
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

  static CustomerPriceRuleSourceType _source(String value) => switch (value) {
    'manual' => CustomerPriceRuleSourceType.manual,
    'excel_import' => CustomerPriceRuleSourceType.excelImport,
    'sales_order' => CustomerPriceRuleSourceType.salesOrder,
    'migration' => CustomerPriceRuleSourceType.migration,
    _ => throw FormatException('Unknown rule source: $value.'),
  };

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

  static int _requiredInt(Map<String, dynamic> map, String field) {
    final value = map[field];
    if (value is! int) {
      throw FormatException('Expected int field $field.');
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
    return DateTime.utc(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
