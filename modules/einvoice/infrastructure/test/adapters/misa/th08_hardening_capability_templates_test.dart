import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_einvoice_infrastructure/src/adapters/misa/me_invoice_provider_adapter.dart';
import 'package:vet45_einvoice_infrastructure/src/adapters/misa/tenant_me_invoice_client_factory.dart';
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
    final handler = client._handlers[functionName];
    if (handler == null) {
      throw StateError('No handler registered for RPC $functionName');
    }
    return await handler(params) as T;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Map<String, dynamic> _templateJson({
  required String id,
  required String name,
  required String series,
  required bool isSendSummary,
}) {
  return {
    'IPTemplateID': id,
    'TemplateName': name,
    'InvTemplateNo': '1',
    'InvSeries': series,
    'Inactive': false,
    'IsSendSummary': isSendSummary,
  };
}

void main() {
  const defaultAppId = 'app-id';
  const defaultBaseUrl = 'https://testapi.meinvoice.vn/api/integration';

  group('th08_hardening_capability_01 — dual template fetch', () {
    test(
      'fetches invoiceWithCode true and false, classifies MTT, keeps IsSendSummary',
      () async {
        final requestedWithCode = <bool>[];
        final fakeSupabase = _FakeEinvoiceRpcSupabase()
          ..registerHandler('read_provider_credentials', (_) async {
            return [
              {
                'base_url': defaultBaseUrl,
                'tax_code': '0100000000',
                'username': 'misa_user',
                'password': 'secret',
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
              jsonEncode({'Success': true, 'Data': 'token-1'}),
              200,
            );
          }
          if (request.url.path.endsWith('/invoice/templates')) {
            final withCode =
                request.url.queryParameters['invoiceWithCode'] == 'true';
            requestedWithCode.add(withCode);
            final data = withCode
                ? [
                    _templateJson(
                      id: 'tpl-c',
                      name: 'Có mã',
                      series: '1C26TYY',
                      isSendSummary: false,
                    ),
                    _templateJson(
                      id: 'tpl-mtt',
                      name: 'MTT',
                      series: '2C26MYY',
                      isSendSummary: false,
                    ),
                  ]
                : [
                    _templateJson(
                      id: 'tpl-k',
                      name: 'Không mã',
                      series: '1K26TYY',
                      isSendSummary: true,
                    ),
                    // Duplicate series already returned in withCode list.
                    _templateJson(
                      id: 'tpl-c-dup',
                      name: 'Dup',
                      series: '1C26TYY',
                      isSendSummary: false,
                    ),
                  ];
            return http.Response(
              jsonEncode({'Success': true, 'Data': jsonEncode(data)}),
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

        final outcome = await adapter.authenticateAndListTemplates(
          tenantId: 'tenant-1',
          connectionId: 'connection-1',
        );

        expect(outcome.isSuccess, isTrue);
        expect(requestedWithCode, containsAll([true, false]));
        expect(requestedWithCode, hasLength(2));

        final templates = outcome.templates;
        expect(templates, hasLength(3));
        expect(templates.map((t) => t.invoiceSeries).toSet(), {
          '1C26TYY',
          '1K26TYY',
          '2C26MYY',
        });

        final mtt = templates.singleWhere((t) => t.templateId == 'tpl-mtt');
        expect(mtt.isMtt, isTrue);
        expect(mtt.invoiceWithCode, isTrue);

        final noCode = templates.singleWhere((t) => t.templateId == 'tpl-k');
        expect(noCode.invoiceWithCode, isFalse);
        expect(noCode.isSendSummary, isTrue);
        expect(noCode.isMtt, isFalse);
      },
    );

    test('skips malformed InvSeries and keeps valid templates', () async {
      final fakeSupabase = _FakeEinvoiceRpcSupabase()
        ..registerHandler('read_provider_credentials', (_) async {
          return [
            {
              'base_url': defaultBaseUrl,
              'tax_code': '0100000000',
              'username': 'misa_user',
              'password': 'secret',
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
            jsonEncode({'Success': true, 'Data': 'token-1'}),
            200,
          );
        }
        if (request.url.path.endsWith('/invoice/templates')) {
          final withCode =
              request.url.queryParameters['invoiceWithCode'] == 'true';
          final data = withCode
              ? [
                  _templateJson(
                    id: 'tpl-ok',
                    name: 'OK',
                    series: '1C26TYY',
                    isSendSummary: false,
                  ),
                  _templateJson(
                    id: 'tpl-bad',
                    name: 'Bad',
                    series: 'BAD',
                    isSendSummary: false,
                  ),
                ]
              : <Map<String, dynamic>>[];
          return http.Response(
            jsonEncode({'Success': true, 'Data': jsonEncode(data)}),
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

      final outcome = await adapter.authenticateAndListTemplates(
        tenantId: 'tenant-1',
        connectionId: 'connection-1',
      );

      expect(outcome.isSuccess, isTrue);
      expect(outcome.templates, hasLength(1));
      expect(outcome.templates.single.templateId, 'tpl-ok');
    });
  });
}
