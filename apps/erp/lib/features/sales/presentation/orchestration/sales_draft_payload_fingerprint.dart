import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:erp/features/sales/presentation.dart';

final class SalesDraftFingerprint {
  const SalesDraftFingerprint({
    required this.payloadHash,
    required this.canonicalJson,
  });

  final String payloadHash;
  final String canonicalJson;
}

/// Canonical SHA-256 fingerprint for draft save/update idempotency.
abstract final class SalesDraftPayloadFingerprint {
  static SalesDraftFingerprint compute({
    required String storeId,
    required String? customerId,
    required String currencyCode,
    required String? orderNote,
    required String? pricingPreviewToken,
    required List<SalesComposeLineVm> lines,
  }) {
    final payload = <String, Object?>{
      'currencyCode': currencyCode.trim().toUpperCase(),
      'customerId': _nullable(customerId),
      'lines': [
        for (final line in lines)
          <String, Object?>{
            'manualDiscountBasisPoints': line.input.manual.discountBasisPoints,
            'manualDiscountMinor': line.input.manual.discountMinor,
            'manualUnitPriceMinor': line.input.manual.unitPriceMinor,
            'productId': line.identity.productId,
            'productUnitId': line.identity.productUnitId,
            'quantity': line.input.quantity,
          },
      ],
      'orderNote': _normalizeNote(orderNote),
      'pricingPreviewToken': _nullable(pricingPreviewToken),
      'storeId': storeId.trim(),
    };
    final canonicalJson = jsonEncode(_sort(payload));
    final digest = sha256.convert(utf8.encode(canonicalJson));
    return SalesDraftFingerprint(
      payloadHash: digest.toString(),
      canonicalJson: canonicalJson,
    );
  }

  static String idempotencyKey({
    required String operation,
    required String identity,
    required String payloadHash,
  }) => '${operation.trim()}:${identity.trim()}:${payloadHash.trim()}';

  static String? _normalizeNote(String? note) {
    final trimmed = note?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  static String? _nullable(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  static Object? _sort(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((key) => key.toString()).toList()..sort();
      return <String, Object?>{
        for (final key in keys) key: _sort(value[key]),
      };
    }
    if (value is List) {
      return [for (final item in value) _sort(item)];
    }
    return value;
  }
}
