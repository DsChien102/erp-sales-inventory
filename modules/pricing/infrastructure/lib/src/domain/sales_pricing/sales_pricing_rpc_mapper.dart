import 'package:vet45_pricing_application/application.dart';

abstract final class SalesPricingRpcMapper {
  static Map<String, dynamic> previewParams(
    SalesWorkingStatePricingInput input,
  ) => {
    'p_tenant_id': input.tenantId,
    'p_store_id': input.storeId,
    'p_customer_id': input.customerId,
    'p_currency_code': input.currencyCode,
    'p_context_version': input.contextVersion,
    'p_effective_at': input.effectiveAt.toUtc().toIso8601String(),
    'p_lines': input.lines.map(_lineParams).toList(growable: false),
  };

  static Map<String, dynamic> manualEvaluationParams(
    EvaluateSalesManualPriceQuery query,
  ) => {
    'p_tenant_id': query.tenantId,
    'p_store_id': query.storeId,
    'p_customer_id': query.customerId,
    'p_product_id': query.productId,
    'p_product_unit_id': query.productUnitId,
    'p_quantity_micros': query.quantityMicros,
    'p_currency_code': query.currencyCode,
    'p_context_version': query.contextVersion,
    'p_manual_unit_price_minor': query.manualUnitPriceMinor,
    'p_manual_discount_minor': query.manualDiscountMinor,
    'p_manual_discount_basis_points': query.manualDiscountBasisPoints,
    'p_acknowledge_below_floor': query.acknowledgeBelowFloor,
  };

  static SalesWorkingStatePricingPreviewDto previewFromPayload(
    Object? payload, {
    required int expectedContextVersion,
    required String expectedCurrencyCode,
    required List<String> expectedLocalLineIds,
  }) {
    try {
      final json = _object(payload, 'response');
      final contextVersion = _integer(
        json['context_version'],
        'context_version',
      );
      final currency = _text(json['currency_code'], 'currency_code');
      if (contextVersion != expectedContextVersion) {
        throw const FormatException('Pricing context version mismatch.');
      }
      if (currency != expectedCurrencyCode) {
        throw const FormatException('Pricing currency mismatch.');
      }

      final rawLines = _list(json['lines'], 'lines');
      final lines = rawLines.map(_previewLine).toList(growable: false);
      final actualIds = lines.map((line) => line.localLineId).toList();
      if (actualIds.toSet().length != actualIds.length ||
          actualIds.length != expectedLocalLineIds.length ||
          !actualIds.toSet().containsAll(expectedLocalLineIds)) {
        throw const FormatException(
          'Pricing response line ids do not match request.',
        );
      }

      return SalesWorkingStatePricingPreviewDto(
        contextVersion: contextVersion,
        previewToken: _text(json['preview_token'], 'preview_token'),
        currencyCode: currency,
        lines: lines,
      );
    } on PricingBlockedException {
      rethrow;
    } on Object {
      throw const PricingBlockedException(
        PricingBlockedCodes.systemError,
        message: 'Malformed sales pricing preview payload.',
      );
    }
  }

  static SalesManualPriceEvaluationDto manualEvaluationFromPayload(
    Object? payload,
  ) {
    try {
      final json = _object(payload, 'response');
      final allowed = _boolean(json['allowed'], 'allowed');
      final requiresAcknowledgement = _boolean(
        json['requires_acknowledgement'],
        'requires_acknowledgement',
      );
      final canViewFloor = _boolean(json['can_view_floor'], 'can_view_floor');
      final floor = _optionalNonNegativeInteger(
        json['floor_price_minor'],
        'floor_price_minor',
      );
      if (!canViewFloor && floor != null) {
        throw const FormatException('Redacted floor price was exposed.');
      }
      if (requiresAcknowledgement && !allowed) {
        throw const FormatException(
          'Blocked result cannot require acknowledgement.',
        );
      }
      return SalesManualPriceEvaluationDto(
        allowed: allowed,
        requiresAcknowledgement: requiresAcknowledgement,
        normalizedUnitPriceMinor: _nonNegativeInteger(
          json['normalized_unit_price_minor'],
          'normalized_unit_price_minor',
        ),
        floorPriceMinor: floor,
        canViewFloor: canViewFloor,
        warningCodes: _strings(json['warning_codes'], 'warning_codes'),
        blockingCode: _optionalText(json['blocking_code'], 'blocking_code'),
        message: _optionalText(json['message'], 'message'),
      );
    } on PricingBlockedException {
      rethrow;
    } on Object {
      throw const PricingBlockedException(
        PricingBlockedCodes.systemError,
        message: 'Malformed manual price evaluation payload.',
      );
    }
  }

  static Map<String, dynamic> _lineParams(SalesPricingLineInput line) => {
    'local_line_id': line.localLineId,
    'product_id': line.productId,
    'product_unit_id': line.productUnitId,
    'quantity_micros': line.quantityMicros,
    'manual_unit_price_minor': line.manualUnitPriceMinor,
    'manual_discount_minor': line.manualDiscountMinor,
    'manual_discount_basis_points': line.manualDiscountBasisPoints,
  };

  static SalesPricingLinePreviewDto _previewLine(Object? value) {
    final json = _object(value, 'line');
    return SalesPricingLinePreviewDto(
      localLineId: _text(json['local_line_id'], 'local_line_id'),
      appliedUnitPriceMinor: _nonNegativeInteger(
        json['applied_unit_price_minor'],
        'applied_unit_price_minor',
      ),
      discountMinor: _nonNegativeInteger(
        json['discount_minor'],
        'discount_minor',
      ),
      lineTotalMinor: _nonNegativeInteger(
        json['line_total_minor'],
        'line_total_minor',
      ),
      sourceCode: _text(json['source_code'], 'source_code'),
      listPriceMinor: _optionalNonNegativeInteger(
        json['list_price_minor'],
        'list_price_minor',
      ),
      floorPriceMinor: _optionalNonNegativeInteger(
        json['floor_price_minor'],
        'floor_price_minor',
      ),
      warningCodes: _strings(json['warning_codes'], 'warning_codes'),
      blockingCodes: _strings(json['blocking_codes'], 'blocking_codes'),
    );
  }

  static Map<String, dynamic> _object(Object? value, String field) {
    if (value is Map) return Map<String, dynamic>.from(value);
    throw FormatException('$field must be an object.');
  }

  static List<dynamic> _list(Object? value, String field) {
    if (value is List) return value;
    throw FormatException('$field must be an array.');
  }

  static String _text(Object? value, String field) {
    if (value is String && value.trim().isNotEmpty) return value;
    throw FormatException('$field must be non-blank text.');
  }

  static String? _optionalText(Object? value, String field) {
    if (value == null) return null;
    if (value is String) return value;
    throw FormatException('$field must be text or null.');
  }

  static bool _boolean(Object? value, String field) {
    if (value is bool) return value;
    throw FormatException('$field must be boolean.');
  }

  static int _integer(Object? value, String field) {
    if (value is int) return value;
    throw FormatException('$field must be an integer.');
  }

  static int _nonNegativeInteger(Object? value, String field) {
    final result = _integer(value, field);
    if (result < 0) throw FormatException('$field cannot be negative.');
    return result;
  }

  static int? _optionalNonNegativeInteger(Object? value, String field) {
    if (value == null) return null;
    return _nonNegativeInteger(value, field);
  }

  static List<String> _strings(Object? value, String field) {
    final values = _list(value, field);
    if (values.any((item) => item is! String || item.trim().isEmpty)) {
      throw FormatException('$field must contain non-blank strings.');
    }
    return values.cast<String>().toList(growable: false);
  }
}
