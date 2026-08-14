import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'package:vet45_misa/src/e_invoice/internal/me_invoice_auth.dart';

void main() {
  group('MeInvoiceAuth', () {
    test('caches token across getToken calls', () async {
      var loginCalls = 0;
      final httpClient = MockClient((request) async {
        expect(request.url.path, endsWith('/auth/token'));
        loginCalls++;
        return http.Response(
          jsonEncode(<String, dynamic>{'Success': true, 'Data': 'cached-token'}),
          200,
        );
      });

      final auth = MeInvoiceAuth(
        baseUrl: 'https://example.test/api/integration',
        appId: 'a',
        taxCode: 't',
        username: 'u',
        password: 'p',
        httpClient: httpClient,
      );

      final first = await auth.getToken();
      final second = await auth.getToken();

      expect(first.value, 'cached-token');
      expect(second.value, 'cached-token');
      expect(loginCalls, 1);
    });

    test('forceRefresh uses refreshtoken then falls back to login', () async {
      var loginCalls = 0;
      var refreshCalls = 0;
      final httpClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/token')) {
          loginCalls++;
          return http.Response(
            jsonEncode(<String, dynamic>{
              'Success': true,
              'Data': 'login-$loginCalls',
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/auth/refreshtoken')) {
          refreshCalls++;
          return http.Response('nope', 500);
        }
        return http.Response('unexpected', 500);
      });

      final auth = MeInvoiceAuth(
        baseUrl: 'https://example.test/api/integration',
        appId: 'a',
        taxCode: 't',
        username: 'u',
        password: 'p',
        httpClient: httpClient,
      );

      await auth.getToken();
      final refreshed = await auth.getToken(forceRefresh: true);

      expect(refreshCalls, 1);
      expect(loginCalls, 2);
      expect(refreshed.value, 'login-2');
    });

    test('seeded token is reused without login', () async {
      var loginCalls = 0;
      final httpClient = MockClient((request) async {
        loginCalls++;
        return http.Response('nope', 500);
      });

      final auth = MeInvoiceAuth(
        baseUrl: 'https://example.test/api/integration',
        httpClient: httpClient,
        initialToken: MeInvoiceAuthToken(
          value: 'seed',
          expiresAt: DateTime.now().toUtc().add(const Duration(days: 1)),
        ),
      );

      final token = await auth.getToken();
      expect(token.value, 'seed');
      expect(loginCalls, 0);
    });

    test('expired bearer without login credentials fails', () async {
      final auth = MeInvoiceAuth(
        baseUrl: 'https://example.test/api/integration',
        httpClient: MockClient((_) async => http.Response('{}', 200)),
        initialToken: MeInvoiceAuthToken(
          value: 'old',
          expiresAt: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
        ),
      );

      expect(
        () => auth.getToken(),
        throwsA(
          isA<MeInvoiceAuthException>().having(
            (e) => e.message,
            'message',
            'meinvoice_token_expired_relogin',
          ),
        ),
      );
    });

    test('isExpired respects skew', () {
      final token = MeInvoiceAuthToken(
        value: 't',
        expiresAt: DateTime.utc(2026, 1, 1, 12),
      );
      expect(
        token.isExpired(now: DateTime.utc(2026, 1, 1, 11, 58)),
        isFalse,
      );
      expect(
        token.isExpired(now: DateTime.utc(2026, 1, 1, 11, 59, 30)),
        isTrue,
      );
    });
  });
}
