import '../../internal/json_helpers.dart';

/// §13.10 PublishInvoiceData — dữ liệu phát hành (USB flow; typed for completeness).
final class MeInvoicePublishInvoiceData {
  const MeInvoicePublishInvoiceData({
    this.refId,
    this.transactionId,
    this.invSeries,
    this.invoiceData,
    this.isInvoiceCalculatingMachine,
    this.isSendEmail,
    this.receiverName,
    this.receiverEmail,
  });

  final String? refId;
  final String? transactionId;
  final String? invSeries;
  final String? invoiceData;
  final bool? isInvoiceCalculatingMachine;
  final bool? isSendEmail;
  final String? receiverName;
  final String? receiverEmail;

  factory MeInvoicePublishInvoiceData.fromJson(Map<String, dynamic> json) {
    return MeInvoicePublishInvoiceData(
      refId: MeInvoiceJsonHelpers.readString(json, 'RefID'),
      transactionId: MeInvoiceJsonHelpers.readString(json, 'TransactionID'),
      invSeries: MeInvoiceJsonHelpers.readString(json, 'InvSeries'),
      invoiceData: MeInvoiceJsonHelpers.readString(json, 'InvoiceData'),
      isInvoiceCalculatingMachine: MeInvoiceJsonHelpers.readBool(
        json,
        'IsInvoiceCalculatingMachine',
      ),
      isSendEmail: MeInvoiceJsonHelpers.readBool(json, 'IsSendEmail'),
      receiverName: MeInvoiceJsonHelpers.readString(json, 'ReceiverName'),
      receiverEmail: MeInvoiceJsonHelpers.readString(json, 'ReceiverEmail'),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'RefID', refId);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'TransactionID', transactionId);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'InvSeries', invSeries);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'InvoiceData', invoiceData);
    MeInvoiceJsonHelpers.writeIfPresent(
      map,
      'IsInvoiceCalculatingMachine',
      isInvoiceCalculatingMachine,
    );
    MeInvoiceJsonHelpers.writeIfPresent(map, 'IsSendEmail', isSendEmail);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'ReceiverName', receiverName);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'ReceiverEmail', receiverEmail);
    return map;
  }
}
