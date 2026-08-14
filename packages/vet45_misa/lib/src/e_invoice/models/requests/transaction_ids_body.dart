import 'dart:convert';

/// Encodes a list of transaction IDs as JSON array body (§7/§8/§11/§12).
String encodeTransactionIdsBody(List<String> transactionIds) {
  return jsonEncode(transactionIds);
}
