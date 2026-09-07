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
    final rawData = MeInvoiceJsonHelpers.readString(json, 'Data');
    List<int>? bytes;
    if (rawData != null && rawData.isNotEmpty) {
      final trimmed = rawData.trim();
      if (trimmed.startsWith('<')) {
        // MISA returns raw XML text for invoice documents (not base64 encoded).
        bytes = utf8.encode(rawData);
      } else {
        try {
          bytes = base64Decode(trimmed);
        } on FormatException {
          // Fallback to UTF-8 bytes if base64 decoding fails.
          bytes = utf8.encode(rawData);
        }
      }
    }
    return MeInvoiceInvoiceDataPublished(
      transactionId:
          MeInvoiceJsonHelpers.readString(json, 'TransactionID') ?? '',
      data: rawData,
      bytes: bytes,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'TransactionID': transactionId};
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'Data', data);
    return map;
  }
}
