import 'dart:convert';

/// Shared JSON read/write helpers for MISA wire payloads.
abstract final class MeInvoiceJsonHelpers {
  static Map<String, dynamic>? asMap(Object? raw) {
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } on Object {
        return null;
      }
    }
    return null;
  }

  static List<Object?> asList(Object? raw) {
    if (raw == null) {
      return const [];
    }
    if (raw is List) {
      return raw;
    }
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded;
        }
        if (decoded is Map) {
          return <Object?>[decoded];
        }
      } on Object {
        return const [];
      }
    }
    if (raw is Map) {
      return <Object?>[raw];
    }
    return const [];
  }

  static bool? readBool(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is bool) {
      return value;
    }
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true') {
        return true;
      }
      if (lower == 'false') {
        return false;
      }
    }
    return null;
  }

  static int? readInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  static double? readDouble(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static String? readString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    final text = value.toString();
    return text.isEmpty ? null : text;
  }

  static DateTime? readDateTime(Map<String, dynamic> json, String key) {
    final text = readString(json, key);
    if (text == null) {
      return null;
    }
    return DateTime.tryParse(text)?.toUtc();
  }

  /// MISA date-only fields (`InvDate`, `OrgInvDate`) use yyyy-MM-dd.
  static String? formatDateOnly(DateTime? value) {
    if (value == null) {
      return null;
    }
    final utc = value.toUtc();
    final y = utc.year.toString().padLeft(4, '0');
    final m = utc.month.toString().padLeft(2, '0');
    final d = utc.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static void writeIfPresent(
    Map<String, dynamic> target,
    String key,
    Object? value,
  ) {
    if (value != null) {
      target[key] = value;
    }
  }

  static void writeStringIfPresent(
    Map<String, dynamic> target,
    String key,
    String? value,
  ) {
    if (value != null) {
      target[key] = value;
    }
  }

  static bool? readSuccess(Map<String, dynamic> json) {
    final value = json['Success'] ?? json['success'];
    if (value is bool) {
      return value;
    }
    return null;
  }

  static String? readErrorCode(Map<String, dynamic> json) {
    final code = json['ErrorCode'] ?? json['errorCode'];
    if (code == null) {
      return null;
    }
    final text = code.toString();
    return text.isEmpty ? null : text;
  }
}
