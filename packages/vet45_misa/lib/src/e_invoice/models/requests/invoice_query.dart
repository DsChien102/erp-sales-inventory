/// Input type for `/invoice/status` (§11).
enum MeInvoiceStatusInputType {
  /// Lấy theo TransactionID.
  transactionId(1),

  /// Lấy theo RefID.
  refId(2);

  const MeInvoiceStatusInputType(this.wireValue);

  final int wireValue;
}

/// Download format query param `downloadDataType` (§8).
enum MeInvoiceDownloadDataType {
  xml('xml'),
  pdf('pdf'),
  all('All');

  const MeInvoiceDownloadDataType(this.wireValue);

  final String wireValue;
}

/// Shared query params for status/download/voucher-paper endpoints.
final class MeInvoiceInvoiceQuery {
  const MeInvoiceInvoiceQuery({
    required this.invoiceWithCode,
    this.invoiceCalcu = false,
  });

  final bool invoiceWithCode;
  final bool invoiceCalcu;

  /// Derives query flags from [invSeries] per MISA §1.6.
  ///
  /// - Index 1 (2nd char): `C` = có mã, `K` = không mã
  /// - Index 4 (5th char): `M` = máy tính tiền (MTT), else thường
  factory MeInvoiceInvoiceQuery.fromInvSeries(String invSeries) {
    final normalized = invSeries.trim();
    final withCode = normalized.length < 2
        ? true
        : normalized[1].toUpperCase() == 'C';
    final calcu = normalized.length >= 5 && normalized[4].toUpperCase() == 'M';
    return MeInvoiceInvoiceQuery(
      invoiceWithCode: withCode,
      invoiceCalcu: calcu,
    );
  }

  Map<String, String> toQueryParameters({
    MeInvoiceStatusInputType? inputType,
    MeInvoiceDownloadDataType? downloadDataType,
    String? converter,
    String? convertDate,
  }) {
    return <String, String>{
      'invoiceWithCode': invoiceWithCode.toString(),
      'invoiceCalcu': invoiceCalcu.toString(),
      if (inputType != null) 'inputType': '${inputType.wireValue}',
      if (downloadDataType != null)
        'downloadDataType': downloadDataType.wireValue,
      if (converter != null) 'Converter': converter,
      if (convertDate != null) 'ConvertDate': convertDate,
    };
  }
}
