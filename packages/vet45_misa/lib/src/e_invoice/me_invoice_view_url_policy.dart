/// Fail-closed HTTPS viewer URL policy for MISA preview/official view links.
abstract final class MeInvoiceViewUrlPolicy {
  /// Returns [raw] when it is an absolute HTTPS URL on an approved MISA host.
  static String? tryParse(String? raw) {
    if (raw == null) {
      return null;
    }
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        !uri.hasScheme ||
        uri.scheme.toLowerCase() != 'https' ||
        !uri.hasAuthority ||
        uri.host.isEmpty) {
      return null;
    }

    if (!_isAllowedHost(uri.host)) {
      return null;
    }

    return trimmed;
  }

  static bool _isAllowedHost(String host) {
    final normalized = host.toLowerCase();
    return normalized == 'meinvoice.vn' || normalized.endsWith('.meinvoice.vn');
  }
}
