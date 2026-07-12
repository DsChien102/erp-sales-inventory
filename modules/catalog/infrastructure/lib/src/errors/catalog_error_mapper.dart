import 'dart:convert';

import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../domain/custom_fields/custom_field_rpc_mapper.dart';

Object mapCatalogRpcError(RpcException error) {
  final message = error.message.toLowerCase();

  if (message.contains('duplicate sku')) {
    return DuplicateSkuException(sku: _extractQuoted(error.message) ?? '');
  }

  if (message.contains('duplicate reference_id')) {
    return DuplicateReferenceIdException(
      referenceId: _extractQuoted(error.message) ?? '',
    );
  }

  if (message.contains('duplicate barcode')) {
    return DuplicateBarcodeException(
      barcode: _extractQuoted(error.message) ?? '',
    );
  }

  if (message.contains('duplicate measurement unit') ||
      message.contains('duplicate product unit')) {
    return DuplicateMeasurementUnitNameException(
      name: _extractQuoted(error.message) ?? '',
    );
  }

  if (message.contains('missing base unit') || message.contains('base_unit_not_found')) {
    return MissingBaseUnitException();
  }

  if (message.contains('not_basic_stock_mode')) {
    return NotBasicStockModeException();
  }

  if (message.contains('not_manual_base_price_mode')) {
    return NotManualBasePriceModeException();
  }

  if (message.contains('store_price_rule_not_found')) {
    return StorePriceRuleNotFoundException();
  }

  if (message.contains('store_price_rule_inactive')) {
    return StorePriceRuleInactiveException();
  }

  if (message.contains('price_band_overwrite_required')) {
    return PriceBandOverwriteRequiredException();
  }

  if (message.contains('stale_base_price')) {
    return StaleBasePriceException();
  }

  if (message.contains('missing_base_price')) {
    return MissingBasePriceException();
  }

  if (message.contains('floor_price_greater_than_list_price')) {
    return FloorPriceGreaterThanListPriceException();
  }

  if (message.contains('inactive_product_unit')) {
    return InactiveProductUnitException();
  }

  if (message.contains('product_conversion_unit_delete_blocked')) {
    return ProductConversionUnitDeleteBlockedException(
      message: _stripKnownPrefix(error.message),
    );
  }

  if (message.contains('duplicate custom field group name')) {
    return DuplicateCustomFieldGroupNameException(
      name: _extractQuoted(error.message) ?? '',
    );
  }

  if (message.contains('duplicate custom field name')) {
    return DuplicateCustomFieldNameException(
      name: _extractQuoted(error.message) ?? '',
      groupId: '',
    );
  }

  if (message.contains('custom field group not found')) {
    return CustomFieldGroupNotFoundException(groupId: '');
  }

  if (message.contains('custom_field_value_validation')) {
    final errors = CustomFieldRpcMapper.validationErrorsFromJson(
      _extractJsonArray(error.message),
    );
    if (errors.isNotEmpty) {
      return CustomFieldValueValidationException(errors: errors);
    }
    return CustomFieldValueValidationException(
      errors: [
        CustomFieldValueValidationErrorDto(
          fieldId: '',
          code: 'invalid',
          message: _stripKnownPrefix(error.message),
        ),
      ],
    );
  }

  if (message.contains('custom field not found')) {
    return CustomFieldNotFoundException(fieldId: _extractQuoted(error.message) ?? '');
  }

  if (message.contains('custom_field_type_change_blocked')) {
    return CustomFieldTypeChangeBlockedException(fieldId: '');
  }

  if (message.contains('stale_stock_quantity')) {
    return StaleStockQuantityException();
  }

  if (message.contains('stale_product_version')) {
    final versions = _extractExpectedCurrent(error.message);
    return StaleProductVersionException(
      expectedVersion: versions.$1,
      currentVersion: versions.$2,
    );
  }

  if (message.contains('product_business_status_warnings_require_acknowledgment')) {
    return ProductBusinessStatusWarningsRequireAcknowledgmentException(
      warnings: _extractBusinessStatusWarnings(error.message),
    );
  }

  if (message.contains('product_delete_blocked') || message.contains('product_restore_blocked')) {
    return ValidationException(_stripKnownPrefix(error.message));
  }

  if (message.contains('validation_exception')) {
    return ValidationException(_stripPrefix(error.message));
  }

  if (message.contains('product name is required')) {
    return ApplicationException('Product name is required.');
  }

  if (message.contains('product not found')) {
    return ApplicationException('Product not found');
  }

  if (message.contains('not authenticated') ||
      message.contains('permission denied') ||
      message.contains('actor mismatch')) {
    return ApplicationException(error.message, cause: error);
  }

  return ApplicationException(error.message, cause: error);
}

String _stripPrefix(String message) {
  return message.replaceFirst(RegExp(r'^validation_exception:\s*'), '');
}

String _stripKnownPrefix(String message) {
  return message.replaceFirst(RegExp(r'^[a-z_]+:\s*'), '');
}

String? _extractQuoted(String message) {
  final match = RegExp(r'"([^"]+)"').firstMatch(message);
  return match?.group(1);
}

(int, int) _extractExpectedCurrent(String message) {
  final expected = RegExp(r'expected=(\d+)').firstMatch(message);
  final current = RegExp(r'current=(\d+)').firstMatch(message);
  return (
    int.tryParse(expected?.group(1) ?? '') ?? 0,
    int.tryParse(current?.group(1) ?? '') ?? 0,
  );
}

List<ProductBusinessStatusWarningDto> _extractBusinessStatusWarnings(
  String message,
) {
  final decoded = _extractJsonArray(message);
  if (decoded == null) {
    return const [];
  }

  try {
    return decoded
        .map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          return ProductBusinessStatusWarningDto(
            code: map['code'] as String,
            message: map['message'] as String,
          );
        })
        .toList(growable: false);
  } on FormatException {
    return const [];
  } on TypeError {
    return const [];
  }
}

List<dynamic>? _extractJsonArray(String message) {
  final jsonStart = message.indexOf('[');
  if (jsonStart < 0) {
    return null;
  }

  try {
    final decoded = jsonDecode(message.substring(jsonStart));
    return decoded is List<dynamic> ? decoded : null;
  } on FormatException {
    return null;
  }
}
