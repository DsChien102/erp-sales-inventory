import 'dart:convert';

import 'package:erp/core/errors/app_exception.dart';

/// Gateway cũ bóc `message` JSON lồng tới 3 lớp (lớp đầu do AppException.from đã đọc).
/// Trả AppException khi gặp mã nằm trong [stableCodes] (PERMISSION_DENIED → NO_PERMISSION).
AppException? unwrapNestedSalesRpcError(String? raw, {required Set<String> stableCodes}) {
  var current = raw;
  for (var depth = 0; depth < 2 && current != null; depth++) {
    final trimmed = current.trim();
    if (!trimmed.startsWith('{')) return null;
    Object? decoded;
    try {
      decoded = jsonDecode(trimmed);
    } on FormatException {
      return null;
    }
    if (decoded is! Map) return null;
    final code = decoded['code'];
    final message = decoded['message'];
    final details = decoded['details'];
    if (code is String) {
      final normalized = code == 'PERMISSION_DENIED' ? 'NO_PERMISSION' : code;
      if (stableCodes.contains(normalized)) {
        return AppException(
          normalized,
          serverMessage: message is String ? message : null,
          details: details is Map ? Map<String, dynamic>.from(details) : null,
        );
      }
    }
    current = message is String ? message : null;
  }
  return null;
}
