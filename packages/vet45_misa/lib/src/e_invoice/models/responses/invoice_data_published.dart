import 'dart:convert';

import '../../internal/json_helpers.dart';

/// Download item from §8 (`InvoiceDataPublished`).
final class MeInvoiceInvoiceDataPublished {
  const MeInvoiceInvoiceDataPublished({
    required this.transactionId,
    this.data,
    this.bytes,
    this.diagnostics,
  });

  final String transactionId;
  final String? data;
  final List<int>? bytes;

  /// Non-document fields of the provider item (e.g. per-item `ErrorCode`),
  /// clipped — for logs when `Data` is missing. Never contains document content.
  final String? diagnostics;

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
      diagnostics: _diagnostics(json),
    );
  }

  static String? _diagnostics(Map<String, dynamic> json) {
    final parts = <String>[];
    for (final entry in json.entries) {
      if (entry.key.toLowerCase() == 'data') {
        continue;
      }
      final text = '${entry.value ?? ''}';
      parts.add(
        '${entry.key}=${text.length <= 120 ? text : '${text.substring(0, 120)}…'}',
      );
    }
    return parts.isEmpty ? null : parts.join(' ');
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'TransactionID': transactionId};
    MeInvoiceJsonHelpers.writeStringIfPresent(map, 'Data', data);
    return map;
  }
}
