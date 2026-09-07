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

  /// Builds a MISA preview invoice data object from provider-neutral canonical schema.
  static MeInvoiceInvoiceData toPreviewInvoice(Map<String, Object?> canonicalInvoice) {
    validate(canonicalInvoice);

    final wireJson = _toWireJsonBody(canonicalInvoice);
    return MeInvoiceInvoiceData.fromJson(wireJson);
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

    return MeInvoicePublishRequest(signType: signType, invoiceData: [invoice]);
  }

  static Map<String, dynamic> _toWireJson(
    Map<String, Object?> canonicalInvoice,
    String idempotencyKey,
  ) {
    final wire = _toWireJsonBody(canonicalInvoice);
    wire['RefID'] = idempotencyKey;
    return wire;
  }

  /// Normalizes camelCase canonical amounts (mirror `*Oc`) then converts to MISA PascalCase.
  static Map<String, dynamic> _toWireJsonBody(
    Map<String, Object?> canonicalInvoice,
  ) {
    final normalized = _normalizeCanonicalAmounts(
      Map<String, dynamic>.from(canonicalInvoice),
    );
    return _convertKeys(normalized);
  }

  /// Fills Original-Currency (`*Oc`) twins when only base amounts are present.
  ///
  /// MISA meInvoice expects `TotalAmountOC` / `AmountOC` even for VND invoices.
  /// Also fills preview-required defaults from the Open API unpublishview example:
  /// `TotalDiscountAmountOC`, `TotalAmountInWords`, line discount fields.
  static Map<String, dynamic> _normalizeCanonicalAmounts(
    Map<String, dynamic> input,
  ) {
    _mirrorAmount(input, from: 'totalAmount', to: 'totalAmountOc');
    _mirrorAmount(input, from: 'totalSaleAmount', to: 'totalSaleAmountOc');
    _mirrorAmount(
      input,
      from: 'totalAmountWithoutVat',
      to: 'totalAmountWithoutVatOc',
    );
    _mirrorAmount(input, from: 'totalVatAmount', to: 'totalVatAmountOc');
    _mirrorAmount(
      input,
      from: 'totalDiscountAmount',
      to: 'totalDiscountAmountOc',
    );

    if (_readAmount(input['totalDiscountAmount']) == null &&
        _readAmount(input['totalDiscountAmountOc']) == null) {
      input['totalDiscountAmount'] = 0;
      input['totalDiscountAmountOc'] = 0;
    }

    final words = input['totalAmountInWords'];
    if (words is! String || words.trim().isEmpty) {
      final total = _readAmount(
        input['totalAmountOc'] ?? input['totalAmount'],
      );
      if (total != null) {
        input['totalAmountInWords'] = vndAmountInWords(total.round());
      }
    }

    final lines = input['originalInvoiceDetail'];
    if (lines is List) {
      input['originalInvoiceDetail'] = [
        for (final line in lines)
          if (line is Map)
            _normalizeLine(Map<String, dynamic>.from(line))
          else
            line,
      ];
    }

    final taxRates = input['taxRateInfo'];
    if (taxRates is List) {
      input['taxRateInfo'] = [
        for (final rate in taxRates)
          if (rate is Map)
            _normalizeTaxRate(Map<String, dynamic>.from(rate))
          else
            rate,
      ];
    }

    return input;
  }

  static Map<String, dynamic> _normalizeLine(Map<String, dynamic> line) {
    _mirrorAmount(line, from: 'amount', to: 'amountOc');
    _mirrorAmount(line, from: 'amountWithoutVat', to: 'amountWithoutVatOc');
    _mirrorAmount(line, from: 'vatAmount', to: 'vatAmountOc');
    _mirrorAmount(line, from: 'discountAmount', to: 'discountAmountOc');

    // Seed lines often only have `amount` (pre-VAT). MISA wants both AmountOC and
    // AmountWithoutVATOC — mirror amount into the without-VAT pair when absent.
    if (_readAmount(line['amountWithoutVat']) == null &&
        _readAmount(line['amountWithoutVatOc']) == null) {
      final amount = _readAmount(line['amount'] ?? line['amountOc']);
      if (amount != null) {
        line['amountWithoutVat'] = amount;
        line['amountWithoutVatOc'] = amount;
      }
    }

    final vatRateName = line['vatRateName'];
    if (vatRateName is! String || vatRateName.trim().isEmpty) {
      final vatRate = line['vatRate'];
      if (vatRate is num) {
        line['vatRateName'] =
            '${vatRate.toString().replaceFirst(RegExp(r'\.0$'), '')}%';
      }
    }

    line.putIfAbsent('itemType', () => 1);
    if (line['sortOrder'] == null && line['lineNumber'] != null) {
      line['sortOrder'] = line['lineNumber'];
    }
    line.putIfAbsent('discountRate', () => 0);
    if (_readAmount(line['discountAmountOc']) == null &&
        _readAmount(line['discountAmount']) == null) {
      line['discountAmountOc'] = 0;
      line['discountAmount'] = 0;
    }
    // MISA line schema uses VATRateName; drop numeric VATRate to avoid InvalidInvoiceData.
    line.remove('vatRate');
    return line;
  }

  static Map<String, dynamic> _normalizeTaxRate(Map<String, dynamic> rate) {
    _mirrorAmount(rate, from: 'vatAmount', to: 'vatAmountOc');
    // `turnover` is the without-VAT base used by build_canonical_invoice.
    if (_readAmount(rate['amountWithoutVatOc']) == null) {
      final turnover = _readAmount(rate['turnover']);
      if (turnover != null) {
        rate['amountWithoutVatOc'] = turnover;
      }
    }
    final vatRateName = rate['vatRateName'];
    if (vatRateName is! String || vatRateName.trim().isEmpty) {
      final vatRate = rate['vatRate'];
      if (vatRate is num) {
        rate['vatRateName'] =
            '${vatRate.toString().replaceFirst(RegExp(r'\.0$'), '')}%';
      }
    }
    // Keep only MISA TaxRateInfo wire fields.
    rate.remove('vatRate');
    rate.remove('turnover');
    return rate;
  }

  static void _mirrorAmount(
    Map<String, dynamic> map, {
    required String from,
    required String to,
  }) {
    if (_readAmount(map[to]) != null) {
      return;
    }
    final value = _readAmount(map[from]);
    if (value != null) {
      map[to] = value;
    }
  }

  /// Minimal VND amount-in-words for positive integers (MISA TotalAmountInWords).
  static String vndAmountInWords(int amount) {
    if (amount < 0) {
      throw ArgumentError.value(amount, 'amount', 'must be non-negative');
    }
    if (amount == 0) {
      return 'Không đồng';
    }

    const digits = [
      'không',
      'một',
      'hai',
      'ba',
      'bốn',
      'năm',
      'sáu',
      'bảy',
      'tám',
      'chín',
    ];

    String threeDigits(int n, {required bool full}) {
      final tram = n ~/ 100;
      final chuc = (n % 100) ~/ 10;
      final donvi = n % 10;
      final parts = <String>[];
      if (tram > 0 || full) {
        if (tram > 0) {
          parts.add('${digits[tram]} trăm');
        } else if (full && (chuc > 0 || donvi > 0)) {
          parts.add('không trăm');
        }
      }
      if (chuc > 1) {
        parts.add('${digits[chuc]} mươi');
        if (donvi == 1) {
          parts.add('mốt');
        } else if (donvi == 5) {
          parts.add('lăm');
        } else if (donvi > 0) {
          parts.add(digits[donvi]);
        }
      } else if (chuc == 1) {
        parts.add('mười');
        if (donvi == 1) {
          parts.add('một');
        } else if (donvi == 5) {
          parts.add('lăm');
        } else if (donvi > 0) {
          parts.add(digits[donvi]);
        }
      } else if (donvi > 0) {
        if (full || tram > 0) {
          parts.add('lẻ ${digits[donvi]}');
        } else {
          parts.add(digits[donvi]);
        }
      }
      return parts.join(' ');
    }

    final ty = amount ~/ 1000000000;
    final trieu = (amount % 1000000000) ~/ 1000000;
    final nghin = (amount % 1000000) ~/ 1000;
    final donvi = amount % 1000;
    final parts = <String>[];
    if (ty > 0) {
      parts.add('${threeDigits(ty, full: false)} tỷ');
    }
    if (trieu > 0) {
      parts.add('${threeDigits(trieu, full: ty > 0)} triệu');
    }
    if (nghin > 0) {
      parts.add('${threeDigits(nghin, full: ty > 0 || trieu > 0)} nghìn');
    }
    if (donvi > 0) {
      parts.add(threeDigits(donvi, full: ty > 0 || trieu > 0 || nghin > 0));
    }
    final words = parts.join(' ').trim();
    final capitalized =
        words.isEmpty ? 'Không' : '${words[0].toUpperCase()}${words.substring(1)}';
    return '$capitalized đồng';
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
      final converted = _convertKeys(Map<String, dynamic>.from(value));
      if (converted.containsKey('VATAmount') &&
          !converted.containsKey('VATAmountOC')) {
        converted['VATAmountOC'] = converted['VATAmount'];
      }
      if (converted.containsKey('Turnover') &&
          !converted.containsKey('AmountWithoutVATOC')) {
        converted['AmountWithoutVATOC'] = converted['Turnover'];
      }
      return converted;
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
    const overrides = {
      'vatRateName': 'VATRateName',
      'vatRate': 'VATRate',
      'vatAmount': 'VATAmount',
      'vatAmountOc': 'VATAmountOC',
      'totalSaleAmount': 'TotalSaleAmount',
      'totalSaleAmountOc': 'TotalSaleAmountOC',
      'totalVatAmount': 'TotalVATAmount',
      'totalVatAmountOc': 'TotalVATAmountOC',
      'totalAmount': 'TotalAmount',
      'totalAmountOc': 'TotalAmountOC',
      'totalDiscountAmount': 'TotalDiscountAmount',
      'totalDiscountAmountOc': 'TotalDiscountAmountOC',
      'totalAmountWithoutVat': 'TotalAmountWithoutVAT',
      'totalAmountWithoutVatOc': 'TotalAmountWithoutVATOC',
      'amountWithoutVat': 'AmountWithoutVAT',
      'amountWithoutVatOc': 'AmountWithoutVATOC',
      'amountOc': 'AmountOC',
      'discountAmountOc': 'DiscountAmountOC',
      'refId': 'RefID',
      'buyerIdNumber': 'BuyerIDNumber',
    };
    return overrides[key] ?? (key[0].toUpperCase() + key.substring(1));
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
