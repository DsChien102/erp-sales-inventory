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
import 'package:vet45_shared_infrastructure/infrastructure.dart';

typedef _EinvoiceRpcHandler =
    Future<dynamic> Function(Map<String, dynamic>? params);

final class _FakeEinvoiceRpcSupabase implements SupabaseClient {
  final Map<String, _EinvoiceRpcHandler> _handlers = {};
  final List<({String functionName, Map<String, dynamic>? params})> calls = [];

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
  }) => _FakePostgrestRpc<T>(client, fn, params);

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
  }) => _execute().then(onValue, onError: onError);

  Future<T> _execute() async {
    client.calls.add((functionName: functionName, params: params));
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

final class _RecordingTextLogger implements ILogger {
  final List<String> warnings = <String>[];

  @override
  void fine(Object? message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void info(Object? message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void severe(Object? message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void warning(Object? message, [Object? error, StackTrace? stackTrace]) {
    warnings.add(message.toString());
  }
}

void main() {
  const defaultAppId = 'test-app-id';
  const defaultBaseUrl = 'https://meinvoice-test.misa.vn';

  final sampleCanonicalInvoice = <String, Object?>{
    'refId': 'ref-100',
    'invSeries': '1C25TYY',
    'signType': 2,
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

  group('MeInvoiceProviderAdapter.authenticateAndListTemplates', () {
    test('logs a safe vendor reason when MISA rejects authentication', () async {
      final fakeSupabase = _FakeEinvoiceRpcSupabase()
        ..registerHandler('read_provider_credentials', (_) async {
          return [
            {
              'base_url': defaultBaseUrl,
              'tax_code': '0100000000',
              'username': 'misa_user',
              'password': 'do-not-log-this-password',
            },
          ];
        });
      final rpcClient = SupabaseSchemaRpcClient(
        supabase: fakeSupabase,
        schema: 'einvoice',
        mapError: (error, [stackTrace]) => RpcException(error.toString()),
      );
      final logger = _RecordingTextLogger();
      final httpClient = MockClient((request) async {
        expect(request.url.path, endsWith('/auth/token'));
        return http.Response(
          jsonEncode({
            'Success': false,
            'ErrorCode': 'UnAuthorize',
            'Errors': <Object>[],
            'Data': null,
          }),
          200,
        );
      });
      final adapter = MeInvoiceProviderAdapter(
        rpcClient: rpcClient,
        clientFactory: TenantMeInvoiceClientFactory(),
        defaultAppId: defaultAppId,
        defaultBaseUrl: defaultBaseUrl,
        httpClient: httpClient,
        logger: logger,
      );

      final outcome = await adapter.authenticateAndListTemplates(
        tenantId: 'tenant-1',
        connectionId: 'connection-1',
      );

      expect(outcome.authFailed, isTrue);
      expect(
        logger.warnings,
        contains(
          'MISA connection verification failed stage=token reason=UnAuthorize',
        ),
      );
      expect(
        logger.warnings.join(),
        isNot(contains('do-not-log-this-password')),
      );
      expect(logger.warnings.join(), isNot(contains('"Success"')));
    });

    test('uses new credentials when a connected tenant reconnects', () async {
      var password = 'old-password';
      final fakeSupabase = _FakeEinvoiceRpcSupabase()
        ..registerHandler('read_provider_credentials', (_) async {
          return [
            {
              'base_url': defaultBaseUrl,
              'tax_code': '0100000000',
              'username': 'misa_user',
              'password': password,
            },
          ];
        });
      final rpcClient = SupabaseSchemaRpcClient(
        supabase: fakeSupabase,
        schema: 'einvoice',
        mapError: (error, [stackTrace]) => RpcException(error.toString()),
      );
      final loginPasswords = <String>[];
      final httpClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/refreshtoken')) {
          return http.Response('{}', 401);
        }
        if (request.url.path.endsWith('/auth/token')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          loginPasswords.add(body['password']! as String);
          return http.Response(
            jsonEncode({
              'Success': true,
              'Data': 'token-${loginPasswords.length}',
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/invoice/templates')) {
          return http.Response(
            jsonEncode({'Success': true, 'Data': '[]'}),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });
      final adapter = MeInvoiceProviderAdapter(
        rpcClient: rpcClient,
        clientFactory: TenantMeInvoiceClientFactory(),
        defaultAppId: defaultAppId,
        defaultBaseUrl: defaultBaseUrl,
        httpClient: httpClient,
      );

      final first = await adapter.authenticateAndListTemplates(
        tenantId: 'tenant-1',
        connectionId: 'connection-1',
      );
      password = 'new-password';
      final second = await adapter.authenticateAndListTemplates(
        tenantId: 'tenant-1',
        connectionId: 'connection-1',
      );

      expect(first.isSuccess, isTrue);
      expect(second.isSuccess, isTrue);
      expect(loginPasswords, ['old-password', 'new-password']);
    });
  });

  group('MeInvoiceProviderAdapter.previewUnpublished', () {
    test('successful preview returns viewerRef', () async {
      final fakeSupabase = _FakeEinvoiceRpcSupabase()
        ..registerHandler('read_provider_credentials', (params) async {
          expect(params?['p_tenant_id'], 'tenant-1');
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

      final httpClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/token')) {
          return http.Response(
            jsonEncode({
              'Success': true,
              'Data': jsonEncode({
                'token': 'test-bearer-token',
                'expires_in': 3600,
              }),
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/invoice/unpublishview')) {
          return http.Response(
            jsonEncode({
              'Success': true,
              'Data': 'https://meinvoice.vn/viewer/preview-uuid-12345',
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final adapter = MeInvoiceProviderAdapter(
        rpcClient: rpcClient,
        clientFactory: TenantMeInvoiceClientFactory(),
        defaultAppId: defaultAppId,
        defaultBaseUrl: defaultBaseUrl,
        httpClient: httpClient,
      );

      final outcome = await adapter.previewUnpublished(
        tenantId: 'tenant-1',
        canonicalInvoice: sampleCanonicalInvoice,
      );

      expect(outcome.isSuccess, isTrue);
      expect(outcome.authFailed, isFalse);
      expect(outcome.providerUnavailable, isFalse);
      expect(
        outcome.viewerRef,
        'https://meinvoice.vn/viewer/preview-uuid-12345',
      );
    });

    test('auth failure when credentials missing in database', () async {
      final fakeSupabase = _FakeEinvoiceRpcSupabase()
        ..registerHandler('read_provider_credentials', (_) async => []);

      final rpcClient = SupabaseSchemaRpcClient(
        supabase: fakeSupabase,
        schema: 'einvoice',
        mapError: (error, [stackTrace]) => RpcException(error.toString()),
      );

      final adapter = MeInvoiceProviderAdapter(
        rpcClient: rpcClient,
        clientFactory: TenantMeInvoiceClientFactory(),
        defaultAppId: defaultAppId,
        defaultBaseUrl: defaultBaseUrl,
      );

      final outcome = await adapter.previewUnpublished(
        tenantId: 'tenant-1',
        canonicalInvoice: sampleCanonicalInvoice,
      );

      expect(outcome.isSuccess, isFalse);
      expect(outcome.authFailed, isTrue);
      expect(outcome.providerUnavailable, isFalse);
      expect(outcome.viewerRef, isNull);
    });

    test('auth failure when MISA auth/login fails', () async {
      final fakeSupabase = _FakeEinvoiceRpcSupabase()
        ..registerHandler('read_provider_credentials', (_) async {
          return [
            {
              'base_url': 'https://meinvoice-test.misa.vn',
              'tax_code': '0100000000',
              'username': 'bad_user',
              'password': 'bad_password',
            },
          ];
        });

      final rpcClient = SupabaseSchemaRpcClient(
        supabase: fakeSupabase,
        schema: 'einvoice',
        mapError: (error, [stackTrace]) => RpcException(error.toString()),
      );

      final httpClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/token')) {
          return http.Response(
            jsonEncode({
              'Success': false,
              'ErrorCode': 'InvalidCredentials',
              'Description': 'Sai tên đăng nhập hoặc mật khẩu',
            }),
            200,
          );
        }
        return http.Response('Unauthorized', 401);
      });

      final adapter = MeInvoiceProviderAdapter(
        rpcClient: rpcClient,
        clientFactory: TenantMeInvoiceClientFactory(),
        defaultAppId: defaultAppId,
        defaultBaseUrl: defaultBaseUrl,
        httpClient: httpClient,
      );

      final outcome = await adapter.previewUnpublished(
        tenantId: 'tenant-1',
        canonicalInvoice: sampleCanonicalInvoice,
      );

      expect(outcome.isSuccess, isFalse);
      expect(outcome.authFailed, isTrue);
      expect(outcome.providerUnavailable, isFalse);
      expect(outcome.viewerRef, isNull);
    });

    test('provider unavailable on network/timeout error', () async {
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

      final httpClient = MockClient((request) async {
        throw http.ClientException('Connection timeout');
      });

      final adapter = MeInvoiceProviderAdapter(
        rpcClient: rpcClient,
        clientFactory: TenantMeInvoiceClientFactory(),
        defaultAppId: defaultAppId,
        defaultBaseUrl: defaultBaseUrl,
        httpClient: httpClient,
      );

      final outcome = await adapter.previewUnpublished(
        tenantId: 'tenant-1',
        canonicalInvoice: sampleCanonicalInvoice,
      );

      expect(outcome.isSuccess, isFalse);
      expect(outcome.providerUnavailable, isTrue);
      expect(outcome.authFailed, isFalse);
      expect(outcome.viewerRef, isNull);
    });

    test('rethrows mapped exception on RpcException', () async {
      final fakeSupabase = _FakeEinvoiceRpcSupabase()
        ..registerHandler('read_provider_credentials', (_) async {
          throw RpcException('EINVOICE_PROVIDER_NOT_CONNECTED');
        });

      final rpcClient = SupabaseSchemaRpcClient(
        supabase: fakeSupabase,
        schema: 'einvoice',
        mapError: (error, [stackTrace]) => RpcException(error.toString()),
      );

      final adapter = MeInvoiceProviderAdapter(
        rpcClient: rpcClient,
        clientFactory: TenantMeInvoiceClientFactory(),
        defaultAppId: defaultAppId,
        defaultBaseUrl: defaultBaseUrl,
      );

      expect(
        () => adapter.previewUnpublished(
          tenantId: 'tenant-1',
          canonicalInvoice: sampleCanonicalInvoice,
        ),
        throwsA(
          isA<EInvoiceBlockedException>().having(
            (e) => e.code,
            'code',
            EInvoiceBlockedCodes.providerNotConnected,
          ),
        ),
      );
    });
  });
}
