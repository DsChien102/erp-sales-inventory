import '../../internal/json_helpers.dart';

/// One item in `publishInvoiceResult[]` (§6 publish response).
final class MeInvoicePublishInvoiceResultItem {
  const MeInvoicePublishInvoiceResultItem({
    this.refId,
    this.transactionId,
    this.invSeries,
    this.invNo,
    this.errorCode,
    this.descriptionErrorCode,
  });

  final String? refId;
  final String? transactionId;
  final String? invSeries;
  final String? invNo;
  final String? errorCode;
  final String? descriptionErrorCode;

  bool get isSuccess => errorCode == null || errorCode!.isEmpty;

  factory MeInvoicePublishInvoiceResultItem.fromJson(
    Map<String, dynamic> json,
  ) {
    return MeInvoicePublishInvoiceResultItem(
      refId: MeInvoiceJsonHelpers.readString(json, 'RefID'),
      transactionId: MeInvoiceJsonHelpers.readString(json, 'TransactionID'),
      invSeries: MeInvoiceJsonHelpers.readString(json, 'InvSeries'),
      invNo: MeInvoiceJsonHelpers.readString(json, 'InvNo'),
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
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'InvNo', invNo);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'ErrorCode', errorCode);
    MeInvoiceJsonHelpers.writeStringIfPresent(
      map,
      'DescriptionErrorCode',
      descriptionErrorCode,
    );
    return map;
  }
}
