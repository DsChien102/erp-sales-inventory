import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_domain/domain.dart';

import 'customer_price_rule_detail_rpc_mapper.dart';

abstract final class PricingRpcMapper {
  static Map<String, dynamic> createContextParams(
    CreateCustomerPriceRuleCommand command,
  ) => <String, dynamic>{
    'p_tenant_id': command.tenantId,
    'p_customer_id': command.customerId,
    'p_product_id': command.productId,
    'p_product_unit_id': command.productUnitId,
    'p_rule_price_minor': command.rulePriceMinor,
    'p_currency_code': command.currencyCode.trim().toUpperCase(),
    'p_effective_from': _date(command.effectiveFrom),
    'p_idempotency_key': command.idempotencyKey.trim(),
    'p_effective_to': command.effectiveTo == null
        ? null
        : _date(command.effectiveTo!),
  };

  static Map<String, dynamic> createParams({
    required CustomerPriceRule candidate,
    required String idempotencyKey,
    required bool acknowledgeFloorWarning,
  }) => <String, dynamic>{
    'p_tenant_id': candidate.key.tenantId,
    'p_rule_id': candidate.id,
    'p_customer_id': candidate.key.customerId,
    'p_product_id': candidate.key.productId,
    'p_product_unit_id': candidate.key.productUnitId,
    'p_rule_price_minor': candidate.price.amountMinor,
    'p_currency_code': candidate.price.currencyCode,
    'p_effective_from': _date(candidate.effectivePeriod.effectiveFrom),
    'p_effective_to': candidate.effectivePeriod.effectiveTo == null
        ? null
        : _date(candidate.effectivePeriod.effectiveTo!),
    'p_note': candidate.note,
    'p_acknowledge_floor_warning': acknowledgeFloorWarning,
    'p_idempotency_key': idempotencyKey.trim(),
  };

  static CustomerPriceRuleCreateContext createContextFromJson(
    Map<String, dynamic> json,
  ) {
    final customer = _map(json['customer']);
    final product = _map(json['product_unit']);
    return CustomerPriceRuleCreateContext(
      customer: CustomerSnapshot(
        customerId: _string(customer, 'customer_id'),
        displayName: _string(customer, 'display_name'),
        phone: customer['phone'] as String?,
        status: _string(customer, 'status'),
        exists: customer['exists'] as bool? ?? false,
        isCustomer: customer['is_customer'] as bool? ?? false,
      ),
      productUnit: ProductPriceBandSnapshot(
        productId: _string(product, 'product_id'),
        productName: _string(product, 'product_name'),
        productUnitId: _string(product, 'product_unit_id'),
        unitName: _string(product, 'unit_name'),
        sellableStatus: _string(product, 'sellable_status'),
        currencyCode: _string(product, 'currency_code'),
        listPriceMinor: _optionalInt(product['list_price_minor']),
        floorPriceMinor: _optionalInt(product['floor_price_minor']),
        floorPriceHidden: product['floor_price_hidden'] as bool? ?? false,
        isBelowFloor: product['is_below_floor'] as bool? ?? false,
      ),
      canOverrideFloor: json['can_override_floor'] as bool? ?? false,
      hasConflictingRule: json['has_conflicting_rule'] as bool? ?? false,
      idempotencyKeyExists: json['idempotency_key_exists'] as bool? ?? false,
      conflictingRuleId: json['conflicting_rule_id'] as String?,
    );
  }

  static CreateCustomerPriceRuleResult createResultFromJson(
    Map<String, dynamic> json,
  ) {
    final rule = _map(json['rule']);
    return CreateCustomerPriceRuleResult(
      rule: CustomerPriceRuleDetailRpcMapper.detailFromJson(rule),
      warnings: _issues(json['warnings']),
    );
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

  static int _requiredInt(Object? value) {
    if (value is int) return value;
    if (value is num && value.isFinite && value == value.truncateToDouble()) {
      return value.toInt();
    }
    throw FormatException('Expected an integer minor-unit value, got $value.');
  }

  static int? _optionalInt(Object? value) =>
      value == null ? null : _requiredInt(value);

  static Map<String, dynamic> _map(Object? value) =>
      value is Map ? value.cast<String, dynamic>() : <String, dynamic>{};

  static String _string(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Expected required string field $key.');
    }
    return value;
  }

  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
