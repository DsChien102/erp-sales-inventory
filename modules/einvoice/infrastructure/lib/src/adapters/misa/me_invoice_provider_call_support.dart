import 'package:vet45_einvoice_application/application.dart';

/// Shared MISA transport/auth classification for slice-4 resource adapters.
abstract final class MeInvoiceProviderCallSupport {
  static const officialViewLeaseMinutes = 5;

  static bool isTransportAmbiguous(String error) {
    final normalized = error.toLowerCase();
    return normalized.contains('timeout') ||
        normalized.contains('meinvoice_network') ||
        normalized.contains('connection') ||
        normalized.contains('meinvoice_5xx') ||
        normalized.contains('unavailable') ||
        normalized.contains('rate_limited') ||
        normalized.contains('429');
  }

  static bool isAuthOrConfigRejection(String error) {
    final normalized = error.toLowerCase();
    return normalized.contains('missing credential') ||
        normalized.contains('missing_misa') ||
        normalized.contains('tokenexpired') ||
        normalized.contains('auth') ||
        normalized.contains('unauthorized') ||
        normalized.contains('forbidden');
  }

  static bool isEmptyProviderPayload(String error) {
    final normalized = error.toLowerCase();
    return normalized.contains('empty_data') ||
        normalized.contains('empty_or_invalid');
  }

  static String safeErrorCode(String error) {
    final trimmed = error.trim();
    final separator = trimmed.indexOf(':');
    final candidate = separator >= 0
        ? trimmed.substring(0, separator).trim()
        : trimmed;
    final match = RegExp(r'^[A-Za-z][A-Za-z0-9_]{0,63}').firstMatch(candidate);
    return match?.group(0) ?? 'UNKNOWN_PROVIDER_FAILURE';
  }

  static void throwIfTransportAmbiguous(String error) {
    if (isTransportAmbiguous(error)) {
      throw ProviderCallAmbiguousException(
        safeErrorCode(error),
        message: error,
      );
    }
  }
}
