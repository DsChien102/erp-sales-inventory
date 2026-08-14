import '../../internal/json_helpers.dart';

/// One email entry in §10 send email request.
final class MeInvoiceSendEmailData {
  const MeInvoiceSendEmailData({
    required this.transactionId,
    this.receiverName,
    this.receiverEmail,
    this.ccEmail,
    this.replyEmail,
  });

  final String transactionId;
  final String? receiverName;
  final String? receiverEmail;
  final String? ccEmail;
  final String? replyEmail;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'TransactionID': transactionId};
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'ReceiverName', receiverName);
    MeInvoiceJsonHelpers.writeStringIfPresent(
      map,
      'ReceiverEmail',
      receiverEmail,
    );
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'CCEmail', ccEmail);
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'ReplyEmail', replyEmail);
    return map;
  }
}

/// POST `/invoice/sendemail` body (§10).
final class MeInvoiceSendEmailRequest {
  const MeInvoiceSendEmailRequest({
    required this.sendEmailDatas,
    required this.isInvoiceCode,
    required this.isInvoiceCalculatingMachine,
  });

  final List<MeInvoiceSendEmailData> sendEmailDatas;
  final bool isInvoiceCode;
  final bool isInvoiceCalculatingMachine;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'SendEmailDatas': sendEmailDatas.map((e) => e.toJson()).toList(),
    'IsInvoiceCode': isInvoiceCode,
    'IsInvoiceCalculatingMachine': isInvoiceCalculatingMachine,
  };
}
