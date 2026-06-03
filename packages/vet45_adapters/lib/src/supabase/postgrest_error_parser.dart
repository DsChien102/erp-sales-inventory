import 'package:supabase/supabase.dart';

/// Parsed fields from a [PostgrestException] for module-specific exception mapping.
final class PostgrestErrorInfo {
  const PostgrestErrorInfo({
    required this.message,
    required this.code,
    this.businessCode,
    this.isAuthentication = false,
    this.isNotFound = false,
    this.isConflict = false,
  });

  final String message;
  final String code;
  final String? businessCode;
  final bool isAuthentication;
  final bool isNotFound;
  final bool isConflict;
}

/// Shared Postgrest parsing helpers — modules map [PostgrestErrorInfo] to their own exceptions.
abstract final class PostgrestErrorParser {
  static PostgrestErrorInfo parse(
    PostgrestException error, {
    required String defaultMessage,
  }) {
    final message = error.message.trim().isEmpty ? defaultMessage : error.message;
    final code = error.code ?? '';
    final businessCode = businessCodeFromDetails(error.details);
    final lower = message.toLowerCase();

    return PostgrestErrorInfo(
      message: message,
      code: code,
      businessCode: businessCode,
      isAuthentication: code == '28000',
      isNotFound: lower.contains('not found'),
      isConflict:
          code == '23505' ||
          lower.contains('conflict') ||
          lower.contains('duplicate') ||
          lower.contains('idempotency'),
    );
  }

  static String? businessCodeFromDetails(Object? details) {
    final value = switch (details) {
      String text => text.trim(),
      null => null,
      _ => details.toString().trim(),
    };
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }
}

typedef PostgrestErrorMapperFn = Object Function(Object error, [StackTrace? stackTrace]);
