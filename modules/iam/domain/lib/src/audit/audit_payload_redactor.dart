/// Result of redacting an audit payload (§S13/§3.4).
final class RedactedAuditPayload {
  const RedactedAuditPayload({required this.payload, required this.flags});

  /// The redacted payload — secrets removed, PII masked.
  final Map<String, Object?> payload;

  /// Stable flags describing which redactions were applied.
  final List<String> flags;
}

/// Redacts IAM audit payloads before they are persisted or returned.
///
/// Two independent concerns:
///   1. Secret denylist — recursively drops credential-like keys (password,
///      token, otp, code, secret, session, ...). These values must NEVER be
///      stored, even masked.
///   2. Deterministic masking — email/phone/tax-code values are masked so an
///      operator can correlate without exposing the raw PII.
abstract final class AuditPayloadRedactor {
  static const Set<String> _secretKeys = {
    'password',
    'new_password',
    'token',
    'access_token',
    'refresh_token',
    'otp',
    'code',
    'verification_code',
    'recovery_code',
    'secret',
    'nonce',
    'session',
    'session_token',
    'token_hash',
  };

  static const Set<String> _emailKeys = {'email', 'contact_email', 'login_email'};
  static const Set<String> _phoneKeys = {'phone', 'phone_number', 'contact_phone'};
  static const Set<String> _taxKeys = {'tax_code', 'tax_id', 'vat_code'};

  static const String flagSecretRemoved = 'SECRET_REMOVED';
  static const String flagEmailMasked = 'EMAIL_MASKED';
  static const String flagPhoneMasked = 'PHONE_MASKED';
  static const String flagTaxCodeMasked = 'TAX_CODE_MASKED';

  static RedactedAuditPayload redact(Map<String, Object?> input) {
    final flags = <String>{};
    final result = _redactMap(input, flags);
    return RedactedAuditPayload(payload: result, flags: flags.toList()..sort());
  }

  static Map<String, Object?> _redactMap(
    Map<String, Object?> input,
    Set<String> flags,
  ) {
    final output = <String, Object?>{};
    input.forEach((key, value) {
      final lower = key.toLowerCase();
      if (_secretKeys.contains(lower)) {
        output[key] = '***';
        flags.add(flagSecretRemoved);
      } else if (_emailKeys.contains(lower) && value is String) {
        output[key] = maskEmail(value);
        flags.add(flagEmailMasked);
      } else if (_phoneKeys.contains(lower) && value is String) {
        output[key] = maskPhone(value);
        flags.add(flagPhoneMasked);
      } else if (_taxKeys.contains(lower) && value is String) {
        output[key] = maskTaxCode(value);
        flags.add(flagTaxCodeMasked);
      } else {
        output[key] = _redactValue(value, flags);
      }
    });
    return output;
  }

  static Object? _redactValue(Object? value, Set<String> flags) {
    if (value is Map<String, Object?>) {
      return _redactMap(value, flags);
    }
    if (value is Map) {
      return _redactMap(value.cast<String, Object?>(), flags);
    }
    if (value is List) {
      return value.map((e) => _redactValue(e, flags)).toList();
    }
    return value;
  }

  /// `lan@gmail.com` -> `l***@gmail.com`.
  static String maskEmail(String email) {
    final at = email.indexOf('@');
    if (at <= 0) {
      return '***';
    }
    return '${email.substring(0, 1)}***${email.substring(at)}';
  }

  /// Keeps the last two digits: `+84901234567` -> `*********67`.
  static String maskPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\s'), '');
    if (digits.length <= 2) {
      return '***';
    }
    final tail = digits.substring(digits.length - 2);
    return '${'*' * (digits.length - 2)}$tail';
  }

  /// Keeps the last three characters: `0312345678` -> `*******678`.
  static String maskTaxCode(String taxCode) {
    if (taxCode.length <= 3) {
      return '***';
    }
    final tail = taxCode.substring(taxCode.length - 3);
    return '${'*' * (taxCode.length - 3)}$tail';
  }
}
