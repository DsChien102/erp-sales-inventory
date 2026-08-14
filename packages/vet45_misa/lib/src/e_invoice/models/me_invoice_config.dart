/// Connection settings for [MeInvoiceClient].
///
/// Auth modes:
/// - **Login:** [appId], [taxCode], [username], [password] (MISA warns against
///   frequent `/auth/token` — prefer caching Bearer ~14 days).
/// - **Bearer:** [accessToken] (+ optional [accessTokenExpiresAt]) skips login
///   until expiry; used by smoke / worker token store.
final class MeInvoiceConfig {
  const MeInvoiceConfig({
    required this.baseUrl,
    this.appId,
    this.taxCode,
    this.username,
    this.password,
    this.accessToken,
    this.accessTokenExpiresAt,
  });

  /// Test environment default base URL.
  static const String testBaseUrl =
      'https://testapi.meinvoice.vn/api/integration';

  /// Production environment default base URL.
  static const String prodBaseUrl = 'https://api.meinvoice.vn/api/integration';

  /// MISA documents Bearer validity ~14 days; avoid login-per-request.
  static const Duration defaultTokenTtl = Duration(days: 14);

  final String baseUrl;
  final String? appId;
  final String? taxCode;
  final String? username;
  final String? password;

  /// Pre-issued Bearer (from smoke token file or tenant token cache).
  final String? accessToken;
  final DateTime? accessTokenExpiresAt;

  bool get hasBearerToken =>
      accessToken != null && accessToken!.trim().isNotEmpty;

  bool get hasLoginCredentials {
    return appId != null &&
        appId!.isNotEmpty &&
        taxCode != null &&
        taxCode!.isNotEmpty &&
        username != null &&
        username!.isNotEmpty &&
        password != null &&
        password!.isNotEmpty;
  }

  /// Returns a stable error code when neither bearer nor login is usable.
  String? get missingCredentialError {
    if (baseUrl.isEmpty) {
      return 'missing_MISA_MEINVOICE_BASE_URL';
    }
    if (hasBearerToken) {
      return null;
    }
    if (appId == null || appId!.isEmpty) {
      return 'missing_MISA_MEINVOICE_APP_ID';
    }
    if (taxCode == null || taxCode!.isEmpty) {
      return 'missing_MISA_MEINVOICE_TAX_CODE';
    }
    if (username == null || username!.isEmpty) {
      return 'missing_MISA_MEINVOICE_USERNAME';
    }
    if (password == null || password!.isEmpty) {
      return 'missing_MISA_MEINVOICE_PASSWORD';
    }
    return null;
  }

  bool get hasCredentials => missingCredentialError == null;
}
