import '../../internal/json_helpers.dart';

/// §13.9 OptionUserDefined — thiết lập số thập phân.
final class MeInvoiceOptionUserDefined {
  const MeInvoiceOptionUserDefined({
    this.mainCurrency,
    this.quantityDecimalDigits,
    this.unitPriceOcDecimalDigits,
    this.amountOcDecimalDigits,
    this.amountDecimalDigits,
    this.coefficientDecimalDigits,
    this.exchangRateDecimalDigits,
  });

  final String? mainCurrency;
  final String? quantityDecimalDigits;
  final String? unitPriceOcDecimalDigits;
  final String? amountOcDecimalDigits;
  final String? amountDecimalDigits;
  final String? coefficientDecimalDigits;
  final String? exchangRateDecimalDigits;

  factory MeInvoiceOptionUserDefined.fromJson(Map<String, dynamic> json) {
    return MeInvoiceOptionUserDefined(
      mainCurrency: MeInvoiceJsonHelpers.readString(json, 'MainCurrency'),
      quantityDecimalDigits: MeInvoiceJsonHelpers.readString(
        json,
        'QuantityDecimalDigits',
      ),
      unitPriceOcDecimalDigits: MeInvoiceJsonHelpers.readString(
        json,
        'UnitPriceOCDecimalDigits',
      ),
      amountOcDecimalDigits: MeInvoiceJsonHelpers.readString(
        json,
        'AmountOCDecimalDigits',
      ),
      amountDecimalDigits: MeInvoiceJsonHelpers.readString(
        json,
        'AmountDecimalDigits',
      ),
      coefficientDecimalDigits: MeInvoiceJsonHelpers.readString(
        json,
        'CoefficientDecimalDigits',
      ),
      exchangRateDecimalDigits: MeInvoiceJsonHelpers.readString(
        json,
        'ExchangRateDecimalDigits',
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'MainCurrency', mainCurrency);
    MeInvoiceJsonHelpers.writeStringIfPresent(
      map,
      'QuantityDecimalDigits',
      quantityDecimalDigits,
    );
    MeInvoiceJsonHelpers.writeStringIfPresent(
      map,
      'UnitPriceOCDecimalDigits',
      unitPriceOcDecimalDigits,
    );
    MeInvoiceJsonHelpers.writeStringIfPresent(
      map,
      'AmountOCDecimalDigits',
      amountOcDecimalDigits,
    );
    MeInvoiceJsonHelpers.writeStringIfPresent(
      map,
      'AmountDecimalDigits',
      amountDecimalDigits,
    );
    MeInvoiceJsonHelpers.writeStringIfPresent(
      map,
      'CoefficientDecimalDigits',
      coefficientDecimalDigits,
    );
    MeInvoiceJsonHelpers.writeStringIfPresent(
      map,
      'ExchangRateDecimalDigits',
      exchangRateDecimalDigits,
    );
    return map;
  }
}
