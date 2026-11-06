import 'dart:convert';

import 'package:erp/core/errors/app_exception.dart';

abstract final class SalesDraftErrorCodes {
  static const noPermission = 'NO_PERMISSION'; // server PERMISSION_DENIED
  static const dataScopeDenied = 'DATA_SCOPE_DENIED';
  static const contextInvalid = 'CONTEXT_INVALID';
  static const referenceUnavailable = 'REFERENCE_UNAVAILABLE';
  static const staleData = 'STALE_DATA';
  static const idempotencyConflict = 'IDEMPOTENCY_CONFLICT';
  static const systemError = 'SYSTEM_ERROR';
}

const Set<String> _stableCodes = {
  SalesDraftErrorCodes.noPermission,
  SalesDraftErrorCodes.dataScopeDenied,
  SalesDraftErrorCodes.contextInvalid,
  SalesDraftErrorCodes.referenceUnavailable,
  SalesDraftErrorCodes.staleData,
  SalesDraftErrorCodes.idempotencyConflict,
};

/// Q7: AppException có mã trong 6 mã ổn định → giữ code, serverMessage, details;
/// còn lại → SYSTEM_ERROR (cause = lỗi gốc).
AppException salesDraftException(Object error) {
  final appError = error is AppException ? error : AppException.from(error);
  if (_stableCodes.contains(appError.code)) {
    return appError;
  }
  final nested = _unwrapNested(appError.serverMessage);
  if (nested != null) return nested;
  return AppException(SalesDraftErrorCodes.systemError, cause: error);
}

/// Gateway cũ bóc `message` JSON lồng tới 3 lớp (lớp đầu do AppException.from đã đọc).
AppException? _unwrapNested(String? raw) {
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
      final normalized = code == 'PERMISSION_DENIED' ? SalesDraftErrorCodes.noPermission : code;
      if (_stableCodes.contains(normalized)) {
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
