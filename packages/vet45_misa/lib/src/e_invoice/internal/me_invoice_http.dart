import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/me_invoice_result.dart';
import '../models/responses/api_response.dart';
import 'api_response_parser.dart';
import 'error_mapper.dart';
import 'me_invoice_auth.dart';

/// Low-level authenticated HTTP helper for meInvoice.
final class MeInvoiceHttp {
  MeInvoiceHttp({required this.auth, required http.Client httpClient})
    : _http = httpClient;

  final MeInvoiceAuth auth;
  final http.Client _http;

  Future<MeInvoiceResult<MeInvoiceApiResponse>> get(
    String path, {
    Map<String, String>? query,
  }) {
    return _send(
      () async {
        final token = await auth.getToken();
        final uri = _uri(path, query);
        return _http.get(uri, headers: _headers(token.value));
      },
    );
  }

  Future<MeInvoiceResult<MeInvoiceApiResponse>> postJson(
    String path, {
    Object? body,
    Map<String, String>? query,
    Map<String, String>? extraHeaders,
  }) {
    return _send(
      () async {
        final token = await auth.getToken();
        final uri = _uri(path, query);
        return _http.post(
          uri,
          headers: _headers(token.value, extra: extraHeaders),
          body: body == null ? null : jsonEncode(body),
        );
      },
    );
  }

  Future<MeInvoiceResult<MeInvoiceApiResponse>> postRaw(
    String path, {
    required String body,
    Map<String, String>? query,
    Map<String, String>? extraHeaders,
  }) {
    return _send(
      () async {
        final token = await auth.getToken();
        final uri = _uri(path, query);
        return _http.post(
          uri,
          headers: _headers(token.value, extra: extraHeaders),
          body: body,
        );
      },
    );
  }

  Future<MeInvoiceResult<MeInvoiceApiResponse>> _send(
    Future<http.Response> Function() request,
  ) async {
    try {
      var response = await request();
      if (_isTokenExpired(response)) {
        await auth.getToken(forceRefresh: true);
        response = await request();
      }
      if (response.statusCode == 429) {
        return MeInvoiceErrorMapper.fromHttp(
          statusCode: response.statusCode,
          body: response.body,
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return MeInvoiceErrorMapper.fromHttp(
          statusCode: response.statusCode,
          body: response.body,
        );
      }
      return MeInvoiceApiResponseParser.parse(response.body);
    } on MeInvoiceAuthException catch (e) {
      return MeInvoiceResult.failed(e.message);
    } on Object catch (e) {
      return MeInvoiceResult.failed('meinvoice_network: $e');
    }
  }

  bool _isTokenExpired(http.Response response) {
    if (MeInvoiceErrorMapper.tryReadErrorCode(response.body) ==
        MeInvoiceErrorMapper.tokenExpiredCode) {
      return true;
    }
    return false;
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final root = auth.baseUrl.endsWith('/')
        ? auth.baseUrl.substring(0, auth.baseUrl.length - 1)
        : auth.baseUrl;
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$root$normalized').replace(queryParameters: query);
  }

  Map<String, String> _headers(
    String token, {
    Map<String, String>? extra,
  }) {
    return <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      if (extra != null) ...extra,
    };
  }
}
