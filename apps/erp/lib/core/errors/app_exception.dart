import 'dart:async';
import 'dart:convert';

import 'package:supabase/supabase.dart';

import 'app_error_messages.dart';

/// Mã lỗi chuẩn hoá dùng chung. Mã riêng của từng nghiệp vụ (vd `HAS_TRANSACTIONS`,
/// `BUYER_TAX_CODE_REQUIRED`) giữ nguyên chuỗi server trả về.
abstract final class AppErrorCode {
  static const noPermission = 'NO_PERMISSION';
  static const notFound = 'NOT_FOUND';
  static const validation = 'VALIDATION_ERROR';
  static const stateChanged = 'STATE_CHANGED';
  static const authRequired = 'AUTHENTICATION_REQUIRED';
  static const tenantSuspended = 'TENANT_SUSPENDED';
  static const tenantClosed = 'TENANT_CLOSED';
  static const network = 'NETWORK_ERROR';
  static const idempotencyConflict = 'IDEMPOTENCY_CONFLICT';
  static const unknown = 'SYSTEM_ERROR';
  static const resendCooldown = 'RESEND_COOLDOWN';
}

final class AppException implements Exception {
  const AppException(this.code, {this.serverMessage, this.details, this.cause});

  /// Mã đã chuẩn hoá.
  final String code;

  /// Phần chi tiết server gửi. Không hiện thẳng cho người dùng.
  final String? serverMessage;

  /// Dữ liệu kèm theo, vd `{"blockers": [...]}` của einvoice.
  final Map<String, dynamic>? details;

  final Object? cause;

  /// Câu hiển thị. [overrides] cho phép feature thay câu của một số mã.
  String userMessage([Map<String, String> overrides = const {}]) =>
      overrides[code] ?? AppErrorMessages.of(code);

  bool get isNoPermission => code == AppErrorCode.noPermission;

  bool get isStateChanged => code == AppErrorCode.stateChanged;

  factory AppException.from(Object error, [StackTrace? stackTrace]) {
    if (error is AppException) return error;

    final parsed = switch (error) {
      PostgrestException e => _fromPostgrest(e),
      AuthException e => _fromAuth(e),
      _ when _isNetwork(error) => _Parsed(code: AppErrorCode.network, cause: error),
      _ => _Parsed(code: AppErrorCode.unknown, cause: error),
    };

    return AppException(
      _normalize(parsed.code),
      serverMessage: parsed.serverMessage,
      details: parsed.details,
      cause: parsed.cause,
    );
  }

  static _Parsed _fromPostgrest(PostgrestException error) {
    final message = error.message.trim();
    if (message.startsWith('{')) {
      final json = _decodeObject(message);
      final rawCode = json?['code'];
      if (json != null && rawCode is String && rawCode.isNotEmpty) {
        final rawMessage = json['message'];
        final rawDetails = json['details'];
        return _Parsed(
          code: rawCode,
          serverMessage: rawMessage is String ? rawMessage : null,
          details: rawDetails is Map ? Map<String, dynamic>.from(rawDetails) : null,
          cause: error,
        );
      }
    }

    final match = _codePattern.firstMatch(message);
    if (match != null) {
      final detail = match.group(2);
      Map<String, dynamic>? details;
      if (detail != null && detail.trimLeft().startsWith('{')) {
        details = _decodeObject(detail.trim());
      }
      return _Parsed(
        code: match.group(1)!,
        serverMessage: detail,
        details: details,
        cause: error,
      );
    }

    final lower = message.toLowerCase();
    if (error.code == '42501' || lower.contains('permission denied')) {
      return _Parsed(
        code: AppErrorCode.noPermission,
        serverMessage: error.message,
        cause: error,
      );
    }
    if (error.code == 'PGRST301' || lower.contains('jwt') || lower.contains('not authenticated')) {
      return _Parsed(
        code: AppErrorCode.authRequired,
        serverMessage: error.message,
        cause: error,
      );
    }
    return _Parsed(
      code: AppErrorCode.unknown,
      serverMessage: error.message,
      cause: error,
    );
  }

  /// Cùng nhánh nhận diện với [IamUiFailureMapper] cho lỗi đăng nhập.
  static _Parsed _fromAuth(AuthException error) {
    final code = error.code?.toLowerCase();
    final message = error.message.toLowerCase();
    if (code == 'invalid_credentials' ||
        message.contains('invalid login') ||
        message.contains('invalid credential')) {
      return _Parsed(code: 'INVALID_CREDENTIALS', serverMessage: error.message, cause: error);
    }
    if (code == 'email_not_confirmed' || message.contains('not confirmed')) {
      return _Parsed(
        code: 'IDENTITY_EMAIL_NOT_VERIFIED',
        serverMessage: error.message,
        cause: error,
      );
    }
    if (code == 'over_email_send_rate_limit' || error.statusCode == '429') {
      final cooldown = _resendAfter.firstMatch(error.message);
      final seconds = cooldown == null ? null : int.tryParse(cooldown.group(1)!);
      if (seconds != null) {
        return _Parsed(
          code: AppErrorCode.resendCooldown,
          serverMessage: error.message,
          details: {'seconds': seconds},
          cause: error,
        );
      }
      return _Parsed(code: 'RATE_LIMITED', serverMessage: error.message, cause: error);
    }
    if (error.statusCode == '401') {
      return _Parsed(
        code: AppErrorCode.authRequired,
        serverMessage: error.message,
        cause: error,
      );
    }
    return _Parsed(
      code: AppErrorCode.unknown,
      serverMessage: error.message,
      cause: error,
    );
  }

  /// Không dùng `dart:io` để file chạy được trên web.
  static bool _isNetwork(Object error) {
    if (error is TimeoutException) return true;
    final typeName = error.runtimeType.toString();
    if (typeName == 'SocketException' || typeName == 'ClientException') return true;
    final text = error.toString().toLowerCase();
    return text.contains('socketexception') ||
        text.contains('clientexception') ||
        text.contains('failed host lookup') ||
        text.contains('connection refused') ||
        text.contains('network is unreachable');
  }

  static Map<String, dynamic>? _decodeObject(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } on FormatException {
      return null;
    }
    return null;
  }

  static String _normalize(String code) => switch (code) {
    'PERMISSION_DENIED' => AppErrorCode.noPermission,
    'RESOURCE_NOT_FOUND' => AppErrorCode.notFound,
    _ => code,
  };

  static final RegExp _resendAfter = RegExp(
    r'after (\d+) seconds?',
    caseSensitive: false,
  );

  static final RegExp _codePattern = RegExp(
    r'^([A-Z][A-Z0-9_]{2,})(?::\s*(.*))?$',
    dotAll: true,
  );

  @override
  String toString() => 'AppException($code${serverMessage == null ? '' : ': $serverMessage'})';
}

final class _Parsed {
  const _Parsed({required this.code, this.serverMessage, this.details, this.cause});

  final String code;
  final String? serverMessage;
  final Map<String, dynamic>? details;
  final Object? cause;
}
