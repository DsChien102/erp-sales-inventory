import 'dart:async';

import 'package:supabase/supabase.dart';
import 'package:test/test.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_infrastructure/src/adapters/misa/me_invoice_delivery_provider_adapter.dart';
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

DeliveryProviderContextDto _context({
  String invoiceSeries = '1C25TYY',
  String? recipientName = 'Buyer Name',
}) {
  return DeliveryProviderContextDto(
    tenantId: 'tenant-1',
    providerConnectionId: 'conn-1',
    providerTransactionId: 'tx-delivery-1',
    invoiceSeries: invoiceSeries,
    recipientEmail: 'buyer@example.com',
    recipientName: recipientName,
  );
}

MeInvoiceDeliveryProviderAdapter _adapter({
  required FakeMeInvoiceClient fakeClient,
  required _FakeEinvoiceRpcSupabase supabase,
}) {
  final factory = TenantMeInvoiceClientFactory();
  factory.setClientForTesting(
    tenantId: 'tenant-1',
    client: fakeClient,
    config: const MeInvoiceConfig(
      baseUrl: MeInvoiceConfig.testBaseUrl,
      appId: 'app-id',
      taxCode: '0101234567',
      username: 'user',
      password: 'pass',
    ),
  );
  return MeInvoiceDeliveryProviderAdapter(
    rpcClient: SupabaseSchemaRpcClient(
      supabase: supabase,
      schema: 'einvoice',
      mapError: (error, [stackTrace]) => RpcException(error.toString()),
    ),
    clientFactory: factory,
    defaultAppId: 'app-id',
    defaultBaseUrl: MeInvoiceConfig.testBaseUrl,
  );
}

void main() {
  group('MeInvoiceDeliveryProviderAdapter', () {
    late _FakeEinvoiceRpcSupabase supabase;
    late FakeMeInvoiceClient fakeClient;

    setUp(() {
      supabase = _FakeEinvoiceRpcSupabase()
        ..registerHandler('read_provider_credentials', (_) async {
          return [
            {
              'tax_code': '0101234567',
              'username': 'user',
              'password': 'pass',
              'base_url': MeInvoiceConfig.testBaseUrl,
            },
          ];
        });
      fakeClient = FakeMeInvoiceClient();
    });

    test(
      'selects tenant client and maps transaction, receiver, and series flags',
      () async {
        final adapter = _adapter(fakeClient: fakeClient, supabase: supabase);

        final outcome = await adapter.sendEmail(_context());

        expect(fakeClient.sendEmailCount, 1);
        final request = fakeClient.lastSendEmailRequest;
        expect(request, isNotNull);
        expect(request!.isInvoiceCode, isTrue);
        expect(request.isInvoiceCalculatingMachine, isFalse);
        expect(request.sendEmailDatas, hasLength(1));
        final data = request.sendEmailDatas.single;
        expect(data.transactionId, 'tx-delivery-1');
        expect(data.receiverEmail, 'buyer@example.com');
        expect(data.receiverName, 'Buyer Name');
        expect(outcome, isA<DeliveryProviderSucceeded>());
        expect(
          (outcome as DeliveryProviderSucceeded).providerReference,
          'tx-delivery-1',
        );
      },
    );

    test('derives calculating-machine flag from MTT invoice series', () async {
      final adapter = _adapter(fakeClient: fakeClient, supabase: supabase);

      await adapter.sendEmail(_context(invoiceSeries: '2C26MYY'));

      final request = fakeClient.lastSendEmailRequest!;
      expect(request.isInvoiceCode, isTrue);
      expect(request.isInvoiceCalculatingMachine, isTrue);
    });

    test(
      'malformed series maps to INVOICE_SERIES_INVALID without HTTP',
      () async {
        final adapter = _adapter(fakeClient: fakeClient, supabase: supabase);

        final outcome = await adapter.sendEmail(
          _context(invoiceSeries: '1X26TYY'),
        );

        expect(fakeClient.sendEmailCount, 0);
        expect(outcome, isA<DeliveryProviderDefiniteFailure>());
        expect(
          (outcome as DeliveryProviderDefiniteFailure).safeErrorCode,
          'INVOICE_SERIES_INVALID',
        );
      },
    );

    test(
      'missing credentials maps to DefiniteFailure without provider call',
      () async {
        supabase.registerHandler('read_provider_credentials', (_) async => []);
        final adapter = _adapter(fakeClient: fakeClient, supabase: supabase);

        final outcome = await adapter.sendEmail(_context());

        expect(fakeClient.sendEmailCount, 0);
        expect(outcome, isA<DeliveryProviderDefiniteFailure>());
        expect(
          (outcome as DeliveryProviderDefiniteFailure).safeErrorCode,
          'PROVIDER_AUTH_FAILED',
        );
      },
    );

    test(
      'envelope acknowledgement maps to Succeeded with provider reference',
      () async {
        fakeClient.enqueueSendEmailEnvelopeAcknowledgement();
        final adapter = _adapter(fakeClient: fakeClient, supabase: supabase);

        final outcome = await adapter.sendEmail(_context());

        expect(outcome, isA<DeliveryProviderSucceeded>());
        expect(
          (outcome as DeliveryProviderSucceeded).providerReference,
          'tx-delivery-1',
        );
      },
    );

    test('does not leak raw provider message into outcomes', () async {
      fakeClient.enqueueSendEmailResult(
        const MeInvoiceResult.failed(
          'InvalidData: RAW BODY buyer@example.com exception stack',
        ),
      );
      final adapter = _adapter(fakeClient: fakeClient, supabase: supabase);

      final outcome = await adapter.sendEmail(_context());

      expect(outcome, isA<DeliveryProviderDefiniteFailure>());
      final failure = outcome as DeliveryProviderDefiniteFailure;
      expect(failure.safeErrorCode, 'InvalidData');
      expect(failure.safeErrorCode, isNot(contains('RAW')));
      expect(failure.safeErrorCode, isNot(contains('@')));
      expect(failure.safeErrorCode, isNot(contains('exception')));
    });

    test('never calls getStatus', () async {
      final adapter = _adapter(fakeClient: fakeClient, supabase: supabase);

      await adapter.sendEmail(_context());

      expect(fakeClient.getStatusCount, 0);
      expect(fakeClient.sendEmailCount, 1);
    });
  });
}
