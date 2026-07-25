import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_pricing_domain/domain.dart';

abstract final class RememberedPriceRpcMapper {
  static Map<String, Object?> params(RememberedPriceRequest request) => {
    'p_tenant_id': request.tenantId,
    'p_request_id': request.id,
    'p_source_order_id': request.sourceOrderId,
    'p_source_order_line_id': request.sourceOrderLineId,
    'p_customer_id': request.customerId,
    'p_product_id': request.productId,
    'p_product_unit_id': request.productUnitId,
    'p_sold_price_minor': request.soldPrice.amountMinor,
    'p_currency_code': request.soldPrice.currencyCode,
    'p_sold_at': request.soldAt.toIso8601String(),
    'p_idempotency_key': request.idempotencyKey,
  };

  static RememberedPriceOutcomeDto outcomeFromJson(Map<String, dynamic> json) {
    final requestId = _requiredString(json, 'request_id');
    final resultType = _parseResultType(_requiredString(json, 'result_type'));
    final ruleId = _optionalString(json['rule_id']);
    final ruleVersion = _optionalPositiveInt(json['rule_version']);
    final reasonCode = _optionalString(json['reason_code']);
    final warnings = _parseWarnings(json['warnings']);
    final isReplay = _requiredBool(json, 'is_replay');

    switch (resultType) {
      case RememberedPriceResultType.created:
      case RememberedPriceResultType.updated:
        if (ruleId == null || ruleVersion == null) {
          throw const FormatException('Successful outcome requires rule identity.');
        }
      case RememberedPriceResultType.skipped:
      case RememberedPriceResultType.blocked:
        if (reasonCode == null) {
          throw const FormatException(
            'Skipped or blocked outcome requires reason code.',
          );
        }
    }

    return RememberedPriceOutcomeDto(
      requestId: requestId,
      resultType: resultType,
      ruleId: ruleId,
      ruleVersion: ruleVersion,
      reasonCode: reasonCode,
      warnings: warnings,
      isReplay: isReplay,
    );
  }

  static RememberedPriceResultType _parseResultType(String value) =>
      switch (value) {
        'created' => RememberedPriceResultType.created,
        'updated' => RememberedPriceResultType.updated,
        'skipped' => RememberedPriceResultType.skipped,
        'blocked' => RememberedPriceResultType.blocked,
        _ => throw FormatException('Unknown remembered price result type: $value'),
      };

  static List<String> _parseWarnings(Object? value) {
    if (value == null) {
      return const [];
    }
    if (value is! List) {
      throw const FormatException('Warnings must be a list of strings.');
    }
    return [
      for (final item in value)
        if (item is! String)
          throw const FormatException('Warnings must be a list of strings.')
        else
          item,
    ];
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Missing or invalid $key.');
    }
    return value;
  }

  static String? _optionalString(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is! String) {
      throw const FormatException('Expected string value.');
    }
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  static int? _optionalPositiveInt(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is! int || value <= 0) {
      throw const FormatException('Rule version must be a positive integer.');
    }
    return value;
  }

  static bool _requiredBool(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! bool) {
      throw FormatException('Missing or invalid $key.');
    }
    return value;
  }
}
