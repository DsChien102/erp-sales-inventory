import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';
import 'package:vet45_iam_application/application.dart';
import 'package:vet45_iam_infrastructure/src/domain/auth/supabase_authenticator.dart';

void main() {
  test('sessionState is absent when no local session exists', () {
    final supabase = _buildClient();
    final authenticator = SupabaseAuthenticator(supabase);

    expect(authenticator.sessionState, AuthSessionState.absent);
  });

  test('sessionState is active for non-expired session', () async {
    final supabase = _buildClient();
    final authenticator = SupabaseAuthenticator(supabase);

    await supabase.auth.setInitialSession(_sessionJson(expSecondsFromNow: 3600));

    expect(authenticator.sessionState, AuthSessionState.active);
  });

  test('sessionState is expired for expired session', () async {
    final supabase = _buildClient();
    final authenticator = SupabaseAuthenticator(supabase);

    await supabase.auth.setInitialSession(_sessionJson(expSecondsFromNow: -3600));

    expect(authenticator.sessionState, AuthSessionState.expired);
  });

  test('signIn maps invalid_credentials AuthException to IamBlockedException', () async {
    final supabase = _buildClient(
      mockResponse: {
        'code': 'invalid_credentials',
        'error_code': 'invalid_credentials',
        'msg': 'Invalid login credentials',
      },
      mockStatusCode: 400,
    );
    final authenticator = SupabaseAuthenticator(supabase);

    expect(
      () => authenticator.signIn(email: 'test@example.com', password: 'wrong'),
      throwsA(
        isA<IamBlockedException>().having(
          (e) => e.code,
          'code',
          IamBlockedCodes.invalidCredentials,
        ),
      ),
    );
  });

  test('signIn maps email_not_confirmed to identityEmailNotVerified', () async {
    final supabase = _buildClient(
      mockResponse: {
        'code': 'email_not_confirmed',
        'error_code': 'email_not_confirmed',
        'msg': 'Email not confirmed',
      },
      mockStatusCode: 400,
    );
    final authenticator = SupabaseAuthenticator(supabase);

    expect(
      () => authenticator.signIn(email: 'test@example.com', password: 'wrong'),
      throwsA(
        isA<IamBlockedException>().having(
          (e) => e.code,
          'code',
          IamBlockedCodes.identityEmailNotVerified,
        ),
      ),
    );
  });
}

SupabaseClient _buildClient({
  Map<String, dynamic>? mockResponse,
  int mockStatusCode = 200,
}) {
  return SupabaseClient(
    'https://example.supabase.co',
    'anon-key',
    httpClient: mockResponse != null
        ? _MockHttpClient((_) async => _MockResponse(jsonEncode(mockResponse), mockStatusCode))
        : null,
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
}

final class _MockResponse {
  const _MockResponse(this.body, this.statusCode);
  final String body;
  final int statusCode;
}

final class _MockHttpClient extends http.BaseClient {
  _MockHttpClient(this._handler);
  final Future<_MockResponse> Function(http.BaseRequest request) _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final resp = await _handler(request);
    return http.StreamedResponse(
      Stream.value(utf8.encode(resp.body)),
      resp.statusCode,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }
}

String _sessionJson({required int expSecondsFromNow}) {
  final nowSeconds = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
  final exp = nowSeconds + expSecondsFromNow;
  final iat = nowSeconds - 60;
  final accessToken = _encodeJwt(exp: exp, iat: iat, sub: 'user-1');

  return jsonEncode({
    'access_token': accessToken,
    'token_type': 'bearer',
    'refresh_token': 'refresh-token',
    'expires_in': exp - iat,
    'user': {
      'id': 'user-1',
      'aud': 'authenticated',
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{},
      'created_at': '2026-01-01T00:00:00.000Z',
      'email': 'owner@vet45.com',
    },
  });
}

String _encodeJwt({
  required int exp,
  required int iat,
  required String sub,
}) {
  final header = _base64UrlEncode({'alg': 'HS256', 'typ': 'JWT'});
  final payload = _base64UrlEncode({
    'sub': sub,
    'aud': 'authenticated',
    'iat': iat,
    'exp': exp,
    'email': 'owner@vet45.com',
    'role': 'authenticated',
  });
  return '$header.$payload.signature';
}

String _base64UrlEncode(Map<String, dynamic> value) {
  return base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
}
