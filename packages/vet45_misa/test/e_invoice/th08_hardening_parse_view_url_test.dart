import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:vet45_misa/e_invoice.dart';
import 'package:vet45_misa/src/e_invoice/internal/api_response_parser.dart';

MeInvoiceClient _clientReturning(Object? data) {
  return MeInvoiceClient(
    config: MeInvoiceConfig(
      baseUrl: MeInvoiceConfig.testBaseUrl,
      accessToken: 'test-token',
      accessTokenExpiresAt: DateTime.now().toUtc().add(const Duration(days: 1)),
    ),
    httpClient: MockClient((request) async {
      return http.Response(
        jsonEncode({'Success': true, 'Data': data}),
        200,
      );
    }),
  );
}

void main() {
  group('th08_hardening_parse — parseDataString fail-closed', () {
    test('accepts non-empty string', () {
      expect(
        MeInvoiceApiResponseParser.parseDataString(
          'https://meinvoice.vn/viewer/a',
        ),
        'https://meinvoice.vn/viewer/a',
      );
    });

    test('empty string becomes null', () {
      expect(MeInvoiceApiResponseParser.parseDataString(''), isNull);
      expect(MeInvoiceApiResponseParser.parseDataString('   '), isNull);
    });

    test('object is not coerced via toString', () {
      expect(
        MeInvoiceApiResponseParser.parseDataString({'url': 'https://x'}),
        isNull,
      );
    });

    test('list is not coerced via toString', () {
      expect(
        MeInvoiceApiResponseParser.parseDataString(['https://meinvoice.vn/x']),
        isNull,
      );
    });

    test('number is not coerced via toString', () {
      expect(MeInvoiceApiResponseParser.parseDataString(42), isNull);
    });
  });

  group('th08_hardening_parse — HTTPS view URL allowlist', () {
    test('accepts absolute https meinvoice.vn host', () {
      expect(
        MeInvoiceViewUrlPolicy.tryParse(
          'https://meinvoice.vn/viewer/preview-1',
        ),
        'https://meinvoice.vn/viewer/preview-1',
      );
      expect(
        MeInvoiceViewUrlPolicy.tryParse(
          'https://api.meinvoice.vn/viewer/x',
        ),
        'https://api.meinvoice.vn/viewer/x',
      );
      expect(
        MeInvoiceViewUrlPolicy.tryParse(
          'https://testapi.meinvoice.vn/viewer/x',
        ),
        'https://testapi.meinvoice.vn/viewer/x',
      );
    });

    test('rejects empty, http, relative and foreign hosts', () {
      expect(MeInvoiceViewUrlPolicy.tryParse(''), isNull);
      expect(MeInvoiceViewUrlPolicy.tryParse('http://meinvoice.vn/x'), isNull);
      expect(MeInvoiceViewUrlPolicy.tryParse('/viewer/relative'), isNull);
      expect(
        MeInvoiceViewUrlPolicy.tryParse('https://evil.example/viewer'),
        isNull,
      );
      expect(
        MeInvoiceViewUrlPolicy.tryParse('javascript:alert(1)'),
        isNull,
      );
    });
  });

  group('th08_hardening_parse — previewPublished client', () {
    test('rejects non-string Data without false success', () async {
      final result = await _clientReturning({'url': 'https://meinvoice.vn/x'}).previewPublished(
        transactionIds: const ['tx-1'],
        companyTaxCode: '0101234567',
      );
      expect(result.isSuccess, isFalse);
      expect(result.error, 'meinvoice_preview_invalid_data');
    });

    test('rejects http URL on allowlisted host', () async {
      final result =
          await _clientReturning(
            'http://meinvoice.vn/viewer/x',
          ).previewPublished(
            transactionIds: const ['tx-1'],
            companyTaxCode: '0101234567',
          );
      expect(result.isSuccess, isFalse);
      expect(result.error, 'meinvoice_preview_invalid_url');
    });

    test('sends classification query flags when provided', () async {
      Uri? requested;
      final client = MeInvoiceClient(
        config: MeInvoiceConfig(
          baseUrl: MeInvoiceConfig.testBaseUrl,
          accessToken: 'test-token',
          accessTokenExpiresAt: DateTime.now().toUtc().add(const Duration(days: 1)),
        ),
        httpClient: MockClient((request) async {
          requested = request.url;
          return http.Response(
            jsonEncode({'Success': true, 'Data': 'https://meinvoice.vn/viewer/ok'}),
            200,
          );
        }),
      );

      final result = await client.previewPublished(
        transactionIds: const ['tx-1'],
        companyTaxCode: '0101234567',
        query: MeInvoiceInvoiceQuery.fromInvSeries('2C26MYY'),
      );

      expect(result.isSuccess, isTrue);
      expect(requested?.path, endsWith('/invoice/publishview'));
      expect(requested?.queryParameters['invoiceWithCode'], 'true');
      expect(requested?.queryParameters['invoiceCalcu'], 'true');
    });

    test('accepts https meinvoice viewer URL', () async {
      final result =
          await _clientReturning(
            'https://meinvoice.vn/viewer/ok',
          ).previewPublished(
            transactionIds: const ['tx-1'],
            companyTaxCode: '0101234567',
          );
      expect(result.isSuccess, isTrue);
      expect(result.data, 'https://meinvoice.vn/viewer/ok');
    });
  });
}
