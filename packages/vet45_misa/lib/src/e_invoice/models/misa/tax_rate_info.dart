import '../../internal/json_helpers.dart';

/// §13.5 TaxRateInfo — tổng hợp thuế suất.
final class MeInvoiceTaxRateInfo {
  const MeInvoiceTaxRateInfo({
    this.vatRateName,
    this.amountWithoutVatOc,
    this.vatAmountOc,
  });

  final String? vatRateName;
  final double? amountWithoutVatOc;
  final double? vatAmountOc;

  factory MeInvoiceTaxRateInfo.fromJson(Map<String, dynamic> json) {
    return MeInvoiceTaxRateInfo(
      vatRateName: MeInvoiceJsonHelpers.readString(json, 'VATRateName'),
      amountWithoutVatOc: MeInvoiceJsonHelpers.readDouble(
        json,
        'AmountWithoutVATOC',
      ),
      vatAmountOc: MeInvoiceJsonHelpers.readDouble(json, 'VATAmountOC'),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'VATRateName', vatRateName);
    MeInvoiceJsonHelpers.writeIfPresent(
      map,
      'AmountWithoutVATOC',
      amountWithoutVatOc,
    );
    MeInvoiceJsonHelpers.writeIfPresent(map, 'VATAmountOC', vatAmountOc);
    return map;
  }
}
