/// Per-invoice result from MISA POST /invoice/sendemail.
final class MeInvoiceSendEmailResultItem {
  const MeInvoiceSendEmailResultItem({
    this.transactionId,
    this.refId,
    this.refDetailId,
    this.sendEmailStatus,
    this.errorCode,
  });

  final String? transactionId;
  final String? refId;
  final String? refDetailId;
  final int? sendEmailStatus;
  final String? errorCode;

  factory MeInvoiceSendEmailResultItem.fromJson(Map<String, dynamic> json) {
    String? text(String key) {
      final value = json[key];
      if (value != null && value is! String) {
        throw FormatException('Invalid $key');
      }
      return value as String?;
    }

    final status = json['SendEmailStatus'];
    if (status != null && status is! int) {
      throw const FormatException('Invalid SendEmailStatus');
    }
    return MeInvoiceSendEmailResultItem(
      transactionId: text('TransactionID'),
      refId: text('RefID'),
      refDetailId: text('RefDetailID'),
      sendEmailStatus: status as int?,
      errorCode: text('ErrorCode'),
    );
  }
}

/// Closed shapes returned by MISA Product and compatible itemized hosts.
enum MeInvoiceSendEmailResponseKind {
  /// Official Product acknowledgement: `success=true`, empty `errors`, `data=""`.
  ///
  /// Means MISA accepted the send operation — not mailbox delivery proof.
  envelopeAcknowledgement,

  /// Itemized per-invoice rows (`SendEmailStatus`, `TransactionID`, …).
  itemized,
}

/// Typed `/invoice/sendemail` success payload.
final class MeInvoiceSendEmailResponse {
  const MeInvoiceSendEmailResponse._({
    required this.kind,
    required this.items,
  });

  const MeInvoiceSendEmailResponse.envelopeAcknowledgement()
    : this._(
        kind: MeInvoiceSendEmailResponseKind.envelopeAcknowledgement,
        items: const <MeInvoiceSendEmailResultItem>[],
      );

  MeInvoiceSendEmailResponse.itemized(
    List<MeInvoiceSendEmailResultItem> items,
  ) : this._(
        kind: MeInvoiceSendEmailResponseKind.itemized,
        items: List.unmodifiable(items),
      );

  final MeInvoiceSendEmailResponseKind kind;
  final List<MeInvoiceSendEmailResultItem> items;
}
