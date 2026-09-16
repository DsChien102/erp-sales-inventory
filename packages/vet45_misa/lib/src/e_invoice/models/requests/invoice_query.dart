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
  /// - Index 4 (5th char): `M` = máy tính tiền (MTT), `T` = thường
  factory MeInvoiceInvoiceQuery.fromInvSeries(String invSeries) {
    final parsed = tryFromInvSeries(invSeries);
    if (parsed == null) {
      throw FormatException('Malformed MISA InvSeries', invSeries);
    }
    return parsed;
  }

  /// Returns null rather than inferring provider flags from malformed input.
  static MeInvoiceInvoiceQuery? tryFromInvSeries(String invSeries) {
    final normalized = invSeries.trim().toUpperCase();
    if (normalized.length < 5) {
      return null;
    }
    final typeChar = normalized[0];
    final codeChar = normalized[1];
    final usageChar = normalized[4];
    if (!const {'1', '2', '5', '6'}.contains(typeChar) ||
        !const {'C', 'K'}.contains(codeChar) ||
        !const {'T', 'M'}.contains(usageChar)) {
      return null;
    }
    return MeInvoiceInvoiceQuery(
      invoiceWithCode: codeChar == 'C',
      invoiceCalcu: usageChar == 'M',
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
      if (downloadDataType != null) 'downloadDataType': downloadDataType.wireValue,
      'Converter': ?converter,
      'ConvertDate': ?convertDate,
    };
  }
}
