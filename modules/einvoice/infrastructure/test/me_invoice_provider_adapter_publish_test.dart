import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_infrastructure/src/adapters/misa/me_invoice_provider_adapter.dart';
import 'package:vet45_einvoice_infrastructure/src/adapters/misa/tenant_me_invoice_client_factory.dart';
import 'package:vet45_misa/e_invoice.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

typedef _EinvoiceRpcHandler =
    Future<dynamic> Function(Map<String, dynamic>? params);

final class _FakeEinvoiceRpcSupabase implements SupabaseClient {
  final Map<String, _EinvoiceRpcHandler> _handlers = {};

  void registerHandler(String functionName, _EinvoiceRpcHandler handler) {
    _handlers[functionName] = handler;
  }

  @override
  SupabaseQuerySchema schema(String schema) {
    if (schema != 'einvoice') {
      throw UnsupportedError('Only einvoice schema is supported.');
    }
    return _FakeEinvoiceQuerySchema(this);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

final class _FakeEinvoiceQuerySchema implements SupabaseQuerySchema {
  _FakeEinvoiceQuerySchema(this.client);
  final _FakeEinvoiceRpcSupabase client;

  @override
  PostgrestFilterBuilder<T> rpc<T>(
    String fn, {
    Map<String, dynamic>? params,
    bool get = false,
  }) =>
      _FakePostgrestRpc<T>(client, fn, params);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

final class _FakePostgrestRpc<T> implements PostgrestFilterBuilder<T> {
  _FakePostgrestRpc(this.client, this.functionName, this.params);

  final _FakeEinvoiceRpcSupabase client;
  final String functionName;
  final Map<String, dynamic>? params;

  @override
  Stream<T> asStream() => throw UnsupportedError('stream not supported');

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) =>
      _execute().then(onValue, onError: onError);

  Future<T> _execute() async {
    final handler = client._handlers[functionName];
    if (handler == null) {
      throw StateError('No handler registered for RPC $functionName');
    }
    final dynamic result = await handler(params);
    return result as T;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Map<String, Object?> _sampleCanonicalInvoice({String refId = 'ref-should-be-overridden'}) {
  return <String, Object?>{
    'refId': refId,
    'invSeries': '1C25TYY',
    'invDate': '2026-08-01',
    'buyerLegalName': 'Công ty ABC',
    'buyerAddress': 'Hà Nội',
    'totalSaleAmountOc': 100000,
    'totalSaleAmount': 100000,
    'totalAmountWithoutVatOc': 100000,
    'totalAmountWithoutVat': 100000,
    'totalVatAmountOc': 10000,
    'totalVatAmount': 10000,
    'totalDiscountAmountOc': 0,
    'totalDiscountAmount': 0,
    'totalAmountOc': 110000,
    'totalAmount': 110000,
    'totalAmountInWords': 'Một trăm mười nghìn đồng',
    'originalInvoiceDetail': [
      {
        'itemType': 1,
        'lineNumber': 1,
        'sortOrder': 1,
        'itemName': 'Dịch vụ khám',
        'quantity': 1,
        'unitPrice': 100000,
        'amountOc': 100000,
        'amount': 100000,
        'amountWithoutVatOc': 100000,
        'amountWithoutVat': 100000,
        'vatRateName': '10%',
        'vatAmountOc': 10000,
        'vatAmount': 10000,
      },
    ],
    'taxRateInfo': [
      {
        'vatRateName': '10%',
        'amountWithoutVatOc': 100000,
        'vatAmountOc': 10000,
      },
    ],
  };
}

MeInvoiceProviderAdapter _buildAdapter({
  required http.Client httpClient,
}) {
  final fakeSupabase = _FakeEinvoiceRpcSupabase()
    ..registerHandler('read_provider_credentials', (_) async {
      return [
        {
          'base_url': 'https://meinvoice-test.misa.vn',
          'tax_code': '0100000000',
          'username': 'misa_user',
          'password': 'misa_password',
        },
      ];
    });

  final rpcClient = SupabaseSchemaRpcClient(
    supabase: fakeSupabase,
    schema: 'einvoice',
    mapError: (error, [stackTrace]) => RpcException(error.toString()),
  );

  return MeInvoiceProviderAdapter(
    rpcClient: rpcClient,
    clientFactory: TenantMeInvoiceClientFactory(),
    defaultAppId: 'test-app-id',
    defaultBaseUrl: 'https://meinvoice-test.misa.vn',
    httpClient: httpClient,
  );
}

http.Response _authOkResponse() {
  return http.Response(
    jsonEncode({
      'Success': true,
      'Data': 'test-bearer-token',
    }),
    200,
  );
}

void main() {
  const tenantId = 'tenant-1';
  const idempotencyKey = 'attempt-key-42';

  group('MeInvoiceProviderAdapter.validateCanonical', () {
    test('accepts a structurally valid canonical invoice', () {
      final adapter = _buildAdapter(
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      );

      expect(
        () => adapter.validateCanonical(
          canonicalInvoice: _sampleCanonicalInvoice(),
        ),
        returnsNormally,
      );
    });

    test('throws on missing buyerLegalName', () {
      final adapter = _buildAdapter(
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      );
      final invalid = _sampleCanonicalInvoice()..remove('buyerLegalName');

      expect(
        () => adapter.validateCanonical(canonicalInvoice: invalid),
        throwsA(
          isA<MeInvoiceCanonicalValidationException>().having(
            (e) => e.reasonCode,
            'reasonCode',
            'CANONICAL_MISSING_buyerLegalName',
          ),
        ),
      );
    });
  });

  group('MeInvoiceProviderAdapter.publish', () {
    test('throws MeInvoiceCanonicalValidationException on invalid canonical', () async {
      final adapter = _buildAdapter(
        httpClient: MockClient((_) async => http.Response('{}', 200)),
      );
      final invalid = _sampleCanonicalInvoice()..remove('buyerLegalName');

      await expectLater(
        adapter.publish(
          tenantId: tenantId,
          canonicalInvoice: invalid,
          idempotencyKey: idempotencyKey,
        ),
        throwsA(
          isA<MeInvoiceCanonicalValidationException>().having(
            (e) => e.reasonCode,
            'reasonCode',
            'CANONICAL_MISSING_buyerLegalName',
          ),
        ),
      );
    });

    test('maps correlated success to MeInvoicePublishSuccess', () async {
      String? capturedRefId;
      final httpClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/token')) {
          return _authOkResponse();
        }
        if (request.url.path.contains('/invoice') &&
            !request.url.path.contains('unpublish')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final invoiceData = body['InvoiceData'] as List<dynamic>;
          capturedRefId = invoiceData.first['RefID'] as String?;
          return http.Response(
            jsonEncode({
              'success': true,
              'publishInvoiceResult': [
                {
                  'RefID': idempotencyKey,
                  'TransactionID': 'tx-success-1',
                  'InvSeries': '1C25TYY',
                  'InvNo': '0000042',
                },
              ],
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final adapter = _buildAdapter(httpClient: httpClient);
      final outcome = await adapter.publish(
        tenantId: tenantId,
        canonicalInvoice: _sampleCanonicalInvoice(),
        idempotencyKey: idempotencyKey,
      );

      expect(outcome, isA<MeInvoicePublishSuccess>());
      expect(capturedRefId, idempotencyKey);
      final success = outcome as MeInvoicePublishSuccess;
      expect(success.providerReference, 'tx-success-1');
      expect(success.invoiceNumber, '0000042');
      expect(success.invoiceSeries, '1C25TYY');
      expect(success.issuedAt, DateTime.utc(2026, 8, 1));
      expect(success.safeProviderEvidence?.refId, idempotencyKey);
    });

    test('maps explicit proven no-side-effect rejection to definiteFailure', () async {
      final httpClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/token')) {
          return _authOkResponse();
        }
        if (request.url.path.contains('/invoice') &&
            !request.url.path.contains('unpublish')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'publishInvoiceResult': [
                {
                  'RefID': idempotencyKey,
                  'ErrorCode': 'InvalidInvSeries',
                  'DescriptionErrorCode': 'Invalid invoice series',
                },
              ],
            }),
            200,
          );
        }
        return http.Response('Not Found ${request.url}', 404);
      });

      final adapter = _buildAdapter(httpClient: httpClient);
      final outcome = await adapter.publish(
        tenantId: tenantId,
        canonicalInvoice: _sampleCanonicalInvoice(),
        idempotencyKey: idempotencyKey,
      );

      expect(outcome, isA<MeInvoicePublishDefiniteFailure>());
      final failure = outcome as MeInvoicePublishDefiniteFailure;
      expect(failure.providerCode, 'InvalidInvSeries');
      expect(failure.providerMessage, 'Invalid invoice series');
      expect(outcome, isNot(isA<MeInvoicePublishUndetermined>()));
    });

    test('maps timeout/network errors to undetermined', () async {
      final httpClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/token')) {
          return _authOkResponse();
        }
        throw http.ClientException('Connection timeout');
      });

      final adapter = _buildAdapter(httpClient: httpClient);
      final outcome = await adapter.publish(
        tenantId: tenantId,
        canonicalInvoice: _sampleCanonicalInvoice(),
        idempotencyKey: idempotencyKey,
      );

      expect(outcome, isA<MeInvoicePublishUndetermined>());
      expect(
        (outcome as MeInvoicePublishUndetermined).reasonCode,
        'PROVIDER_TIMEOUT',
      );
    });

    test('maps malformed response to undetermined', () async {
      final httpClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/token')) {
          return _authOkResponse();
        }
        if (request.url.path.contains('/invoice') &&
            !request.url.path.contains('unpublish')) {
          return http.Response('not-json', 200);
        }
        return http.Response('Not Found', 404);
      });

      final adapter = _buildAdapter(httpClient: httpClient);
      final outcome = await adapter.publish(
        tenantId: tenantId,
        canonicalInvoice: _sampleCanonicalInvoice(),
        idempotencyKey: idempotencyKey,
      );

      expect(outcome, isA<MeInvoicePublishUndetermined>());
      expect(
        (outcome as MeInvoicePublishUndetermined).reasonCode,
        'PROVIDER_MALFORMED_RESPONSE',
      );
    });

    test('maps uncorrelated RefID to undetermined', () async {
      final httpClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/token')) {
          return _authOkResponse();
        }
        if (request.url.path.contains('/invoice') &&
            !request.url.path.contains('unpublish')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'publishInvoiceResult': [
                {
                  'RefID': 'different-ref',
                  'TransactionID': 'tx-1',
                  'InvSeries': '1C25TYY',
                  'InvNo': '0000001',
                },
              ],
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final adapter = _buildAdapter(httpClient: httpClient);
      final outcome = await adapter.publish(
        tenantId: tenantId,
        canonicalInvoice: _sampleCanonicalInvoice(),
        idempotencyKey: idempotencyKey,
      );

      expect(outcome, isA<MeInvoicePublishUndetermined>());
      expect(
        (outcome as MeInvoicePublishUndetermined).reasonCode,
        'PROVIDER_UNCORRELATED_RESPONSE',
      );
    });

    test(
      'DuplicateInvoiceRefID with embedded invoice number stays undetermined',
      () async {
        final httpClient = MockClient((request) async {
          if (request.url.path.endsWith('/auth/token')) {
            return _authOkResponse();
          }
          if (request.url.path.contains('/invoice') &&
            !request.url.path.contains('unpublish')) {
            return http.Response(
              jsonEncode({
                'success': true,
                'publishInvoiceResult': [
                  {
                    'RefID': idempotencyKey,
                    'TransactionID': 'tx-dup',
                    'InvSeries': '1C25TYY',
                    'InvNo': '0000999',
                    'ErrorCode': MeInvoicePublishErrorCodes.duplicateInvoiceRefId,
                    'DescriptionErrorCode': 'RefID already exists',
                  },
                ],
              }),
              200,
            );
          }
          return http.Response('Not Found', 404);
        });

        final adapter = _buildAdapter(httpClient: httpClient);
        final outcome = await adapter.publish(
          tenantId: tenantId,
          canonicalInvoice: _sampleCanonicalInvoice(),
          idempotencyKey: idempotencyKey,
        );

        expect(outcome, isA<MeInvoicePublishUndetermined>());
        expect(outcome, isNot(isA<MeInvoicePublishSuccess>()));
        expect(outcome, isNot(isA<MeInvoicePublishDefiniteFailure>()));
        final undetermined = outcome as MeInvoicePublishUndetermined;
        expect(undetermined.reasonCode, 'DUPLICATE_INVOICE_REF_ID');
        expect(undetermined.safeProviderEvidence?.invoiceNumber, '0000999');
        expect(undetermined.safeProviderEvidence?.refId, idempotencyKey);
      },
    );
  });
}
