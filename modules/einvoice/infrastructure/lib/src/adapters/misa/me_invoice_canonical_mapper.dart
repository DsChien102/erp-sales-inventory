import 'package:vet45_misa/e_invoice.dart';

/// Pure canonical → MISA request mapping and preflight validation.
abstract final class MeInvoiceCanonicalMapper {
  static const _requiredStringFields = <String>[
    'invSeries',
    'invDate',
    'buyerLegalName',
    'buyerAddress',
  ];

  /// Validates provider-neutral canonical schema before publish dispatch.
  static void validate(Map<String, Object?> canonicalInvoice) {
    for (final field in _requiredStringFields) {
      final value = canonicalInvoice[field];
      if (value is! String || value.trim().isEmpty) {
        throw CanonicalValidationFault(
          'CANONICAL_MISSING_$field',
          message: 'Missing or blank canonical field: $field',
        );
      }
    }

    final signType = canonicalInvoice['signType'];
    if (signType != null &&
        signType is! int &&
        !_isValidSignTypeWireValue(signType)) {
      throw const CanonicalValidationFault(
        'CANONICAL_INVALID_SIGN_TYPE',
        message: 'Invalid canonical signType',
      );
    }
    if (signType is int && !_isValidSignTypeWireValue(signType)) {
      throw const CanonicalValidationFault(
        'CANONICAL_INVALID_SIGN_TYPE',
        message: 'Invalid canonical signType wire value',
      );
    }

    final totalAmount = _readAmount(
      canonicalInvoice['totalAmount'] ?? canonicalInvoice['totalAmountOc'],
    );
    if (totalAmount == null || totalAmount <= 0) {
      throw const CanonicalValidationFault(
        'CANONICAL_INVALID_TOTAL_AMOUNT',
        message: 'Canonical total amount must be positive',
      );
    }

    final lines = _readLineItems(canonicalInvoice['originalInvoiceDetail']);
    if (lines.isEmpty) {
      throw const CanonicalValidationFault(
        'CANONICAL_MISSING_LINES',
        message: 'Canonical originalInvoiceDetail must contain line items',
      );
    }
    for (var i = 0; i < lines.length; i++) {
      _validateLine(lines[i], index: i);
    }

    final taxRates = _readLineItems(canonicalInvoice['taxRateInfo']);
    if (taxRates.isEmpty) {
      throw const CanonicalValidationFault(
        'CANONICAL_MISSING_TAX_RATES',
        message: 'Canonical taxRateInfo must contain at least one entry',
      );
    }
  }

  /// Builds a MISA publish request with [idempotencyKey] as correlation RefID.
  static MeInvoicePublishRequest toPublishRequest({
    required Map<String, Object?> canonicalInvoice,
    required String idempotencyKey,
  }) {
    validate(canonicalInvoice);

    final wireJson = _toWireJson(canonicalInvoice, idempotencyKey);
    final invoice = MeInvoiceInvoiceData.fromJson(wireJson);
    final signType = _resolveSignType(canonicalInvoice);

    return MeInvoicePublishRequest(
      signType: signType,
      invoiceData: [invoice],
    );
  }

  static Map<String, dynamic> _toWireJson(
    Map<String, Object?> canonicalInvoice,
    String idempotencyKey,
  ) {
    final wire = _convertKeys(Map<String, dynamic>.from(canonicalInvoice));
    wire['RefID'] = idempotencyKey;
    return wire;
  }

  static Map<String, dynamic> _convertKeys(Map<String, dynamic> input) {
    final output = <String, dynamic>{};
    for (final entry in input.entries) {
      final key = _toPascalCaseKey(entry.key);
      output[key] = _convertValue(entry.value);
    }
    return output;
  }

  static Object? _convertValue(Object? value) {
    if (value is Map) {
      return _convertKeys(Map<String, dynamic>.from(value));
    }
    if (value is List) {
      return value.map(_convertValue).toList();
    }
    return value;
  }

  static String _toPascalCaseKey(String key) {
    if (key.isEmpty) {
      return key;
    }
    return key[0].toUpperCase() + key.substring(1);
  }

  static MeInvoiceSignType _resolveSignType(Map<String, Object?> canonical) {
    final raw = canonical['signType'];
    if (raw is int) {
      return MeInvoiceSignType.values.firstWhere(
        (value) => value.wireValue == raw,
        orElse: () => MeInvoiceSignType.hsmWithCks,
      );
    }
    return MeInvoiceSignType.hsmWithCks;
  }

  static bool _isValidSignTypeWireValue(Object value) {
    if (value is! int) {
      return false;
    }
    return MeInvoiceSignType.values.any((item) => item.wireValue == value);
  }

  static double? _readAmount(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }

  static List<Map<String, Object?>> _readLineItems(Object? raw) {
    if (raw is! List) {
      return const [];
    }
    return raw
        .whereType<Map>()
        .map((item) => Map<String, Object?>.from(item))
        .toList();
  }

  static void _validateLine(Map<String, Object?> line, {required int index}) {
    final itemName = line['itemName'];
    if (itemName is! String || itemName.trim().isEmpty) {
      throw CanonicalValidationFault(
        'CANONICAL_INVALID_LINE_ITEM_NAME',
        message: 'Line $index itemName is required',
      );
    }

    final quantity = _readAmount(line['quantity']);
    if (quantity == null || quantity <= 0) {
      throw CanonicalValidationFault(
        'CANONICAL_INVALID_LINE_QUANTITY',
        message: 'Line $index quantity must be positive',
      );
    }

    final hasUnitPrice = _readAmount(line['unitPrice']) != null;
    final hasAmount = _readAmount(line['amount'] ?? line['amountOc']) != null;
    if (!hasUnitPrice && !hasAmount) {
      throw CanonicalValidationFault(
        'CANONICAL_INVALID_LINE_AMOUNT',
        message: 'Line $index must include unitPrice or amount',
      );
    }
  }
}

/// Infrastructure-local validation fault mapped to application exception.
final class CanonicalValidationFault implements Exception {
  const CanonicalValidationFault(this.reasonCode, {this.message});

  final String reasonCode;
  final String? message;

  @override
  String toString() => message ?? reasonCode;
}
