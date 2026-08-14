import '../../internal/json_helpers.dart';

/// §13.11 InvoiceStatus — trạng thái hóa đơn.
final class MeInvoiceInvoiceStatus {
  const MeInvoiceInvoiceStatus({
    this.refId,
    this.invSeries,
    this.invTempl,
    this.buyerName,
    this.buyerTaxCode,
    this.buyerCode,
    this.buyerFullName,
    this.transactionId,
    this.publishStatus,
    this.eInvoiceStatus,
    this.referenceType,
    this.invoiceCode,
    this.sourceType,
    this.sendTaxStatus,
    this.publishedTime,
    this.invNo,
  });

  final String? refId;
  final String? invSeries;
  final String? invTempl;
  final String? buyerName;
  final String? buyerTaxCode;
  final String? buyerCode;
  final String? buyerFullName;
  final String? transactionId;
  final int? publishStatus;
  final int? eInvoiceStatus;
  final int? referenceType;
  final String? invoiceCode;
  final String? sourceType;
  final num? sendTaxStatus;
  final DateTime? publishedTime;
  final String? invNo;

  factory MeInvoiceInvoiceStatus.fromJson(Map<String, dynamic> json) {
    return MeInvoiceInvoiceStatus(
      refId: MeInvoiceJsonHelpers.readString(json, 'RefID'),
      invSeries: MeInvoiceJsonHelpers.readString(json, 'InvSeries'),
      invTempl: MeInvoiceJsonHelpers.readString(json, 'InvTempl'),
      buyerName: MeInvoiceJsonHelpers.readString(json, 'BuyerName'),
      buyerTaxCode: MeInvoiceJsonHelpers.readString(json, 'BuyerTaxCode'),
      buyerCode: MeInvoiceJsonHelpers.readString(json, 'BuyerCode'),
      buyerFullName: MeInvoiceJsonHelpers.readString(json, 'BuyerFullName'),
      transactionId: MeInvoiceJsonHelpers.readString(json, 'TransactionID'),
      publishStatus: MeInvoiceJsonHelpers.readInt(json, 'PublishStatus'),
      eInvoiceStatus: MeInvoiceJsonHelpers.readInt(json, 'EInvoiceStatus'),
      referenceType: MeInvoiceJsonHelpers.readInt(json, 'ReferenceType'),
      invoiceCode: MeInvoiceJsonHelpers.readString(json, 'InvoiceCode'),
      sourceType: MeInvoiceJsonHelpers.readString(json, 'SourceType'),
      sendTaxStatus: json['SendTaxStatus'] as num?,
      publishedTime: MeInvoiceJsonHelpers.readDateTime(json, 'PublishedTime'),
      invNo: MeInvoiceJsonHelpers.readString(json, 'InvNo'),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'RefID', refId);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'InvSeries', invSeries);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'InvTempl', invTempl);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'BuyerName', buyerName);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'BuyerTaxCode', buyerTaxCode);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'BuyerCode', buyerCode);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'BuyerFullName', buyerFullName);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'TransactionID', transactionId);
    MeInvoiceJsonHelpers.writeIfPresent(map, 'PublishStatus', publishStatus);
    MeInvoiceJsonHelpers.writeIfPresent(map, 'EInvoiceStatus', eInvoiceStatus);
    MeInvoiceJsonHelpers.writeIfPresent(map, 'ReferenceType', referenceType);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'InvoiceCode', invoiceCode);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'SourceType', sourceType);
    MeInvoiceJsonHelpers.writeIfPresent(map, 'SendTaxStatus', sendTaxStatus);
    MeInvoiceJsonHelpers.writeIfPresent(
      map,
      'PublishedTime',
      publishedTime?.toUtc().toIso8601String(),
    );
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'InvNo', invNo);
    return map;
  }
}
