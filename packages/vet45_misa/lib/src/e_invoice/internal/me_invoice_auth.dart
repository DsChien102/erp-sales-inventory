import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/me_invoice_config.dart';
import 'error_mapper.dart';

/// Cached access token for meInvoice API.
final class MeInvoiceAuthToken {
  const MeInvoiceAuthToken({required this.value, required this.expiresAt});

  final String value;
  final DateTime expiresAt;

  bool isExpired({DateTime? now, Duration skew = const Duration(minutes: 1)}) {
    final clock = now ?? DateTime.now().toUtc();
    return !clock.isBefore(expiresAt.toUtc().subtract(skew));
  }
}

/// Obtains and caches Bearer tokens; supports one refresh on expiry.
///
/// Prefer [seed] / constructor [initialToken] and reuse for ~7 days (MISA recommendation; max validity ~14 days).
/// Calling [/auth/token] on every invoice risks MISA IP blocks.
final class MeInvoiceAuth {
  MeInvoiceAuth({
    required this.baseUrl,
    this.appId,
    this.taxCode,
    this.username,
    this.password,
    required http.Client httpClient,
    MeInvoiceAuthToken? initialToken,
    Duration defaultTtl = MeInvoiceConfig.recommendedTokenTtl,
    Duration requestTimeout = const Duration(seconds: 60),
  }) : _http = httpClient,
       _defaultTtl = defaultTtl,
       _requestTimeout = requestTimeout,
       _cached = initialToken;

  final String baseUrl;
  final String? appId;
  final String? taxCode;
  final String? username;
  final String? password;
  final http.Client _http;
  final Duration _defaultTtl;
  final Duration _requestTimeout;

  MeInvoiceAuthToken? _cached;

  MeInvoiceAuthToken? get cachedToken => _cached;

  /// Seeds or replaces the in-memory cache (e.g. load from disk / Redis).
  void seed(MeInvoiceAuthToken token) => _cached = token;

  /// Clears cache (e.g. after TokenExpiredCode).
  void invalidate() => _cached = null;

  bool get canLogin =>
      appId != null &&
      appId!.isNotEmpty &&
      taxCode != null &&
      taxCode!.isNotEmpty &&
      username != null &&
      username!.isNotEmpty &&
      password != null &&
      password!.isNotEmpty;

  Future<MeInvoiceAuthToken> getToken({bool forceRefresh = false}) async {
    final cached = _cached;
    if (!forceRefresh && cached != null && !cached.isExpired()) {
      return cached;
    }
    if (forceRefresh && cached != null) {
      final refreshed = await _tryRefresh(cached.value);
      if (refreshed != null) {
        _cached = refreshed;
        return refreshed;
      }
    }
    if (!canLogin) {
      throw MeInvoiceAuthException(
        cached != null && cached.isExpired()
            ? 'meinvoice_token_expired_relogin'
            : 'meinvoice_token_missing_relogin',
      );
    }
    final minted = await _login();
    _cached = minted;
    return minted;
  }

  Future<MeInvoiceAuthToken?> _tryRefresh(String oldToken) async {
    final uri = Uri.parse('$baseUrl/auth/refreshtoken');
    final response = await _postWithTimeout(
      uri,
      body: oldToken,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }
    return _parseTokenResponse(response.body);
  }

  Future<MeInvoiceAuthToken> _login() async {
    final uri = Uri.parse('$baseUrl/auth/token');
    final response = await _postWithTimeout(
      uri,
      body: jsonEncode(<String, String>{
        'appid': appId!,
        'taxcode': taxCode!,
        'username': username!,
        'password': password!,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final vendorCode = MeInvoiceErrorMapper.tryReadAuthErrorCode(
        response.body,
      );
      throw MeInvoiceAuthException(
        'meinvoice_auth_http_${response.statusCode}:${vendorCode ?? 'request_failed'}',
      );
    }
    final token = _parseTokenResponse(response.body);
    if (token == null) {
      final vendorCode = MeInvoiceErrorMapper.tryReadAuthErrorCode(
        response.body,
      );
      throw MeInvoiceAuthException(
        vendorCode == null
            ? 'meinvoice_auth_invalid_response'
            : 'meinvoice_auth_rejected:$vendorCode',
      );
    }
    return token;
  }

  Future<http.Response> _postWithTimeout(
    Uri uri, {
    required String body,
  }) async {
    try {
      return await _http
          .post(
            uri,
            headers: const <String, String>{
              'Content-Type': 'application/json',
            },
            body: body,
          )
          .timeout(_requestTimeout);
    } on TimeoutException {
      throw MeInvoiceAuthException('meinvoice_network_timeout');
    }
  }

  MeInvoiceAuthToken? _parseTokenResponse(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        return null;
      }
      final success = decoded['Success'] ?? decoded['success'];
      if (success == false) {
        return null;
      }
      final data = decoded['Data'] ?? decoded['data'];
      if (data is! String || data.isEmpty) {
        return null;
      }
      return MeInvoiceAuthToken(
        value: data,
        expiresAt: DateTime.now().toUtc().add(_defaultTtl),
      );
    } on Object {
      return null;
    }
  }
}

/// Thrown when login / refresh fails hard.
final class MeInvoiceAuthException implements Exception {
  MeInvoiceAuthException(this.message);
  final String message;

  @override
  String toString() => 'MeInvoiceAuthException($message)';
}
