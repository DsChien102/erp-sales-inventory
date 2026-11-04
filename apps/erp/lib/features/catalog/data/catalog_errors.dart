/// Catalog error codes and error classification.
library;

import 'dart:convert';

import 'package:erp/core/errors/app_exception.dart';

abstract final class CatalogErrorCodes {
  static const duplicateSku = 'DUPLICATE_SKU'; // details: {'value': '<sku>'}
  static const duplicateBarcode = 'DUPLICATE_BARCODE'; // details: {'value': '<barcode>'}
  static const duplicateReferenceId = 'DUPLICATE_REFERENCE_ID'; // details: {'value': ...}
  static const duplicateProductUnit = 'DUPLICATE_PRODUCT_UNIT'; // details: {'value': '<tên>'}
  static const missingBaseUnit = 'MISSING_BASE_UNIT';
  static const notBasicStockMode = 'NOT_BASIC_STOCK_MODE';
  static const notManualBasePriceMode = 'NOT_MANUAL_BASE_PRICE_MODE';
  static const storePriceRuleNotFound = 'STORE_PRICE_RULE_NOT_FOUND';
  static const storePriceRuleInactive = 'STORE_PRICE_RULE_INACTIVE';
  static const priceBandOverwriteRequired = 'PRICE_BAND_OVERWRITE_REQUIRED';
  static const staleBasePrice = 'STALE_BASE_PRICE';
  static const missingBasePrice = 'MISSING_BASE_PRICE';
  static const floorGreaterThanList = 'FLOOR_GREATER_THAN_LIST';
  static const inactiveProductUnit = 'INACTIVE_PRODUCT_UNIT';
  static const conversionUnitDeleteBlocked = 'CONVERSION_UNIT_DELETE_BLOCKED'; // serverMessage: lý do (đã bỏ tiền tố)
  static const duplicateCustomFieldGroupName = 'DUPLICATE_CUSTOM_FIELD_GROUP_NAME';
  static const duplicateCustomFieldName = 'DUPLICATE_CUSTOM_FIELD_NAME';
  static const customFieldGroupNotFound = 'CUSTOM_FIELD_GROUP_NOT_FOUND';
  static const customFieldValueValidation = 'CUSTOM_FIELD_VALUE_VALIDATION'; // details: {'errors': [{field_id, group_id, code, message}]}
  static const customFieldNotFound = 'CUSTOM_FIELD_NOT_FOUND';
  static const customFieldTypeChangeBlocked = 'CUSTOM_FIELD_TYPE_CHANGE_BLOCKED';
  static const staleStockQuantity = 'STALE_STOCK_QUANTITY';
  static const invalidStockQuantity = 'INVALID_STOCK_QUANTITY';
  static const staleProductVersion = 'STALE_PRODUCT_VERSION'; // details: {'expected': int, 'current': int}
  static const statusWarningsRequireAck = 'BUSINESS_STATUS_WARNINGS_REQUIRE_ACK'; // details: {'warnings': [{code, message}]}
  static const productDeleteBlocked = 'PRODUCT_DELETE_BLOCKED'; // serverMessage: phần sau tiền tố
  static const productRestoreBlocked = 'PRODUCT_RESTORE_BLOCKED'; // serverMessage: phần sau tiền tố
  static const productSoftDeleted = 'PRODUCT_SOFT_DELETED';
  static const productNotFound = 'PRODUCT_NOT_FOUND';
  static const productNameRequired = 'PRODUCT_NAME_REQUIRED';
}

/// Phân loại lại lỗi RPC catalog sang [AppException] với mã riêng.
AppException catalogException(AppException error) {
  if (error.code != AppErrorCode.unknown) {
    return error;
  }

  final m = error.serverMessage ?? '';
  final lower = m.toLowerCase();

  if (lower.contains('duplicate sku')) {
    return AppException(
      CatalogErrorCodes.duplicateSku,
      serverMessage: m,
      details: {'value': _extractQuoted(m) ?? ''},
      cause: error.cause,
    );
  }

  if (lower.contains('duplicate reference_id')) {
    return AppException(
      CatalogErrorCodes.duplicateReferenceId,
      serverMessage: m,
      details: {'value': _extractQuoted(m) ?? ''},
      cause: error.cause,
    );
  }

  if (lower.contains('duplicate barcode')) {
    return AppException(
      CatalogErrorCodes.duplicateBarcode,
      serverMessage: m,
      details: {'value': _extractQuoted(m) ?? ''},
      cause: error.cause,
    );
  }

  if (lower.contains('duplicate measurement unit') ||
      lower.contains('duplicate product unit')) {
    return AppException(
      CatalogErrorCodes.duplicateProductUnit,
      serverMessage: m,
      details: {'value': _extractQuoted(m) ?? ''},
      cause: error.cause,
    );
  }

  if (lower.contains('missing base unit') || lower.contains('base_unit_not_found')) {
    return AppException(
      CatalogErrorCodes.missingBaseUnit,
      serverMessage: m,
      cause: error.cause,
    );
  }

  if (lower.contains('not_basic_stock_mode')) {
    return AppException(
      CatalogErrorCodes.notBasicStockMode,
      serverMessage: m,
      cause: error.cause,
    );
  }

  if (lower.contains('not_manual_base_price_mode')) {
    return AppException(
      CatalogErrorCodes.notManualBasePriceMode,
      serverMessage: m,
      cause: error.cause,
    );
  }

  if (lower.contains('store_price_rule_not_found')) {
    return AppException(
      CatalogErrorCodes.storePriceRuleNotFound,
      serverMessage: m,
      cause: error.cause,
    );
  }

  if (lower.contains('store_price_rule_inactive')) {
    return AppException(
      CatalogErrorCodes.storePriceRuleInactive,
      serverMessage: m,
      cause: error.cause,
    );
  }

  if (lower.contains('price_band_overwrite_required')) {
    return AppException(
      CatalogErrorCodes.priceBandOverwriteRequired,
      serverMessage: m,
      cause: error.cause,
    );
  }

  if (lower.contains('stale_base_price')) {
    return AppException(
      CatalogErrorCodes.staleBasePrice,
      serverMessage: m,
      cause: error.cause,
    );
  }

  if (lower.contains('missing_base_price')) {
    return AppException(
      CatalogErrorCodes.missingBasePrice,
      serverMessage: m,
      cause: error.cause,
    );
  }

  if (lower.contains('floor_price_greater_than_list_price') ||
      lower.contains('floor_before_vat_greater_than_list_before_vat') ||
      lower.contains('floor_after_vat_greater_than_list_after_vat')) {
    return AppException(
      CatalogErrorCodes.floorGreaterThanList,
      serverMessage: m,
      cause: error.cause,
    );
  }

  if (lower.contains('inactive_product_unit')) {
    return AppException(
      CatalogErrorCodes.inactiveProductUnit,
      serverMessage: m,
      cause: error.cause,
    );
  }

  if (lower.contains('product_conversion_unit_delete_blocked')) {
    return AppException(
      CatalogErrorCodes.conversionUnitDeleteBlocked,
      serverMessage: _stripKnownPrefix(m),
      cause: error.cause,
    );
  }

  if (lower.contains('duplicate custom field group name')) {
    return AppException(
      CatalogErrorCodes.duplicateCustomFieldGroupName,
      serverMessage: m,
      details: {'value': _extractQuoted(m) ?? ''},
      cause: error.cause,
    );
  }

  if (lower.contains('duplicate custom field name')) {
    return AppException(
      CatalogErrorCodes.duplicateCustomFieldName,
      serverMessage: m,
      details: {'value': _extractQuoted(m) ?? ''},
      cause: error.cause,
    );
  }

  if (lower.contains('custom field group not found')) {
    return AppException(
      CatalogErrorCodes.customFieldGroupNotFound,
      serverMessage: m,
      cause: error.cause,
    );
  }

  if (lower.contains('custom_field_value_validation')) {
    final jsonArray = _extractJsonArray(m);
    List<Map<String, dynamic>> errors = const [];
    if (jsonArray != null && jsonArray.isNotEmpty) {
      errors = jsonArray
          .whereType<Map>()
          .map((item) {
            final map = Map<String, dynamic>.from(item);
            return <String, dynamic>{
              'field_id': map['field_id']?.toString() ?? '',
              if (map['group_id'] != null) 'group_id': map['group_id']?.toString(),
              'code': map['code']?.toString() ?? 'invalid',
              'message': map['message']?.toString() ?? '',
            };
          })
          .toList(growable: false);
    }
    if (errors.isEmpty) {
      errors = [
        {
          'field_id': '',
          'code': 'invalid',
          'message': _stripKnownPrefix(m),
        },
      ];
    }
    return AppException(
      CatalogErrorCodes.customFieldValueValidation,
      serverMessage: m,
      details: {'errors': errors},
      cause: error.cause,
    );
  }

  if (lower.contains('custom field not found')) {
    return AppException(
      CatalogErrorCodes.customFieldNotFound,
      serverMessage: m,
      details: {'value': _extractQuoted(m) ?? ''},
      cause: error.cause,
    );
  }

  if (lower.contains('custom_field_type_change_blocked')) {
    return AppException(
      CatalogErrorCodes.customFieldTypeChangeBlocked,
      serverMessage: m,
      cause: error.cause,
    );
  }

  if (lower.contains('stale_stock_quantity')) {
    return AppException(
      CatalogErrorCodes.staleStockQuantity,
      serverMessage: m,
      cause: error.cause,
    );
  }

  if (lower.contains('invalid_stock_quantity')) {
    return AppException(
      CatalogErrorCodes.invalidStockQuantity,
      serverMessage: m,
      cause: error.cause,
    );
  }

  if (lower.contains('stale_product_version')) {
    final versions = _extractExpectedCurrent(m);
    return AppException(
      CatalogErrorCodes.staleProductVersion,
      serverMessage: m,
      details: {'expected': versions.$1, 'current': versions.$2},
      cause: error.cause,
    );
  }

  if (lower.contains('product_business_status_warnings_require_acknowledgment')) {
    final warnings = _extractBusinessStatusWarnings(m);
    return AppException(
      CatalogErrorCodes.statusWarningsRequireAck,
      serverMessage: m,
      details: {'warnings': warnings},
      cause: error.cause,
    );
  }

  if (lower.contains('product_delete_blocked')) {
    return AppException(
      CatalogErrorCodes.productDeleteBlocked,
      serverMessage: _stripKnownPrefix(m),
      cause: error.cause,
    );
  }

  if (lower.contains('product_restore_blocked')) {
    return AppException(
      CatalogErrorCodes.productRestoreBlocked,
      serverMessage: _stripKnownPrefix(m),
      cause: error.cause,
    );
  }

  // Mới (TH-02 6.4): đặt trước validation_exception
  if (lower.contains('product is soft-deleted')) {
    return AppException(
      CatalogErrorCodes.productSoftDeleted,
      serverMessage: m,
      cause: error.cause,
    );
  }

  if (lower.contains('validation_exception')) {
    return AppException(
      AppErrorCode.validation,
      serverMessage: _stripPrefix(m),
      cause: error.cause,
    );
  }

  if (lower.contains('product name is required')) {
    return AppException(
      CatalogErrorCodes.productNameRequired,
      serverMessage: 'Product name is required.',
      cause: error.cause,
    );
  }

  if (lower.contains('product not found') || lower.contains('product_not_found')) {
    return AppException(
      CatalogErrorCodes.productNotFound,
      serverMessage: 'Product not found',
      cause: error.cause,
    );
  }

  if (lower.contains('actor mismatch') ||
      lower.contains('permission denied') ||
      lower.contains('not authenticated')) {
    return AppException(
      AppErrorCode.noPermission,
      serverMessage: m,
      cause: error.cause,
    );
  }

  return error;
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

List<Map<String, dynamic>> _extractBusinessStatusWarnings(String message) {
  final decoded = _extractJsonArray(message);
  if (decoded == null) {
    return const [];
  }

  try {
    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  } catch (_) {
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

