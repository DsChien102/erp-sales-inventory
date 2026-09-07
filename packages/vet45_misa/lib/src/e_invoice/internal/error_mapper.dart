import 'dart:convert';

import '../models/me_invoice_result.dart';

/// Maps HTTP / vendor error payloads to [MeInvoiceResult] failures.
abstract final class MeInvoiceErrorMapper {
  static const tokenExpiredCode = 'TokenExpiredCode';
  static const _authErrorCodes = <String>{
    'InvalidAppID',
    'InactiveAppID',
    'TaxCodeNotExist',
    'InactiveTaxCode',
    'UserNotExist',
    'WrongPassWord',
    'InactiveUser',
    'MisaIdError',
    'TwoFactorAuthen',
    'UnAuthorize',
  };

  static MeInvoiceResult<T> fromHttp<T>({
    required int statusCode,
    required String body,
  }) {
    if (statusCode == 429) {
      return MeInvoiceResult<T>.failed(
        'meinvoice_429_rate_limited',
        rateLimited: true,
      );
    }
    final vendorCode = tryReadErrorCode(body);
    if (vendorCode == tokenExpiredCode) {
      return MeInvoiceResult<T>.failed(tokenExpiredCode);
    }
    final message = vendorCode ?? _truncate(body);
    return MeInvoiceResult<T>.failed('meinvoice_$statusCode: $message');
  }

  static MeInvoiceResult<T> fromVendorPayload<T>(Map<Object?, Object?> map) {
    final code = (map['ErrorCode'] ?? map['errorCode'] ?? map['code'])?.toString();
    final message =
        (map['ErrorMessage'] ??
                map['descriptionErrorCode'] ??
                map['Errors'] ??
                map['errors'] ??
                code ??
                'vendor_error')
            .toString();
    if (code == tokenExpiredCode || message.contains(tokenExpiredCode)) {
      return MeInvoiceResult<T>.failed(tokenExpiredCode);
    }
    return MeInvoiceResult<T>.failed(
      code == null || code.isEmpty ? message : '$code: $message',
    );
  }

  static String? tryReadErrorCode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final code = decoded['ErrorCode'] ?? decoded['errorCode'];
        if (code is String && code.isNotEmpty) {
          return code;
        }
      }
    } on Object {
      // ignore parse errors
    }
    return null;
  }

  /// Reads the most specific documented authentication code without exposing
  /// MISA's full response body. `UnAuthorize` can wrap a detailed code in the
  /// `Errors` string list (for example `WrongPassWord` or `InactiveUser`).
  static String? tryReadAuthErrorCode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        return null;
      }

      final errors = decoded['Errors'] ?? decoded['errors'];
      if (errors is List) {
        for (final error in errors) {
          final text = error?.toString() ?? '';
          for (final code in _authErrorCodes) {
            if (code != 'UnAuthorize' && text.contains(code)) {
              return code;
            }
          }
        }
      }

      final outerCode = (decoded['ErrorCode'] ?? decoded['errorCode'])?.toString();
      return _authErrorCodes.contains(outerCode) ? outerCode : null;
    } on Object {
      return null;
    }
  }

  static String _truncate(String value, [int max = 200]) {
    if (value.length <= max) {
      return value;
    }
    return '${value.substring(0, max)}…';
  }
}
