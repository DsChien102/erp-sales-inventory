import 'package:vet45_pricing_application/application.dart';

import 'customer_price_rule_detail_rpc_mapper.dart';

abstract final class PricingReenableRpcMapper {
  static Map<String, dynamic> precheckParams(
    PrecheckCustomerPriceRuleReenableQuery query,
  ) => {
    'p_tenant_id': query.tenantId,
    'p_rule_id': query.ruleId,
    'p_expected_version': query.expectedVersion,
    'p_business_date': _date(query.businessDate),
  };

  static CustomerPriceRuleReenablePrecheckDto precheckResultFromJson(
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

  static Map<String, dynamic> reenableParams(
    ReenableCustomerPriceRuleCommand command,
  ) => {
    'p_tenant_id': command.tenantId,
    'p_rule_id': command.ruleId,
    'p_expected_version': command.expectedVersion,
    'p_business_date': _date(command.businessDate),
    'p_precheck_token': command.precheckToken,
    'p_acknowledge_floor_warning': command.acknowledgeFloorWarning,
    'p_acknowledge_overwrite': command.acknowledgeOverwrite,
  };

  static CustomerPriceRuleDetailDto reenableResultFromJson(
    Map<String, dynamic> json,
  ) => CustomerPriceRuleDetailRpcMapper.detailFromJson(json);

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
    );
  }

  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  static DateTime _calendarDate(String value) {
    final parts = value.split('-');
    if (parts.length != 3) {
      throw FormatException('Invalid calendar date: $value.');
    }
    return DateTime.utc(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  static Map<String, dynamic> _requiredMap(Object? value, String field) {
    if (value is! Map) {
      throw FormatException('Expected map for $field.');
    }
    return Map<String, dynamic>.from(value);
  }

  static String _requiredString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Expected non-empty string for $field.');
    }
    return value;
  }

  static bool _requiredBool(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is! bool) {
      throw FormatException('Expected bool for $field.');
    }
    return value;
  }

  static List<String> _requiredStrings(Object? value, String field) {
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
}
