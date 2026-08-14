import '../../internal/json_helpers.dart';

/// One item in `createInvoiceResult[]` (§5.1 USB/XML flow — typed for completeness).
final class MeInvoiceCreateInvoiceResultItem {
  const MeInvoiceCreateInvoiceResultItem({
    this.refId,
    this.transactionId,
    this.invSeries,
    this.invoiceData,
    this.errorCode,
    this.descriptionErrorCode,
  });

  final String? refId;
  final String? transactionId;
  final String? invSeries;
  final String? invoiceData;
  final String? errorCode;
  final String? descriptionErrorCode;

  bool get isSuccess => errorCode == null || errorCode!.isEmpty;

  factory MeInvoiceCreateInvoiceResultItem.fromJson(Map<String, dynamic> json) {
    return MeInvoiceCreateInvoiceResultItem(
      refId: MeInvoiceJsonHelpers.readString(json, 'RefID'),
      transactionId: MeInvoiceJsonHelpers.readString(json, 'TransactionID'),
      invSeries: MeInvoiceJsonHelpers.readString(json, 'InvSeries'),
      invoiceData: MeInvoiceJsonHelpers.readString(json, 'InvoiceData'),
      errorCode: MeInvoiceJsonHelpers.readString(json, 'ErrorCode'),
      descriptionErrorCode: MeInvoiceJsonHelpers.readString(
        json,
        'DescriptionErrorCode',
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'RefID', refId);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'TransactionID', transactionId);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'InvSeries', invSeries);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'InvoiceData', invoiceData);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'ErrorCode', errorCode);
    MeInvoiceJsonHelpers.writeStringIfPresent(
      map,
      'DescriptionErrorCode',
      descriptionErrorCode,
    );
    return map;
  }
}
