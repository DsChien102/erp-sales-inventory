import 'dart:convert';

import '../../internal/json_helpers.dart';

/// Download item from §8 (`InvoiceDataPublished`).
final class MeInvoiceInvoiceDataPublished {
  const MeInvoiceInvoiceDataPublished({
    required this.transactionId,
    this.data,
    this.bytes,
  });

  final String transactionId;
  final String? data;
  final List<int>? bytes;

  factory MeInvoiceInvoiceDataPublished.fromJson(Map<String, dynamic> json) {
    final b64 = MeInvoiceJsonHelpers.readString(json, 'Data');
    List<int>? bytes;
    if (b64 != null && b64.isNotEmpty) {
      try {
        bytes = base64Decode(b64);
      } on FormatException {
        bytes = null;
      }
    }
    return MeInvoiceInvoiceDataPublished(
      transactionId:
          MeInvoiceJsonHelpers.readString(json, 'TransactionID') ?? '',
      data: b64,
      bytes: bytes,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'TransactionID': transactionId};
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'Data', data);
    return map;
  }
}
