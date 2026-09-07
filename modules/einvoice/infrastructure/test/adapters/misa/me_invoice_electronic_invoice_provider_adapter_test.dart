import 'dart:async';

import 'package:supabase/supabase.dart';
import 'package:test/test.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_einvoice_infrastructure/src/adapters/misa/me_invoice_electronic_invoice_provider_adapter.dart';
import 'package:vet45_einvoice_infrastructure/src/adapters/misa/me_invoice_observation_classifier.dart';
import 'package:vet45_einvoice_infrastructure/src/adapters/misa/tenant_me_invoice_client_factory.dart';
import 'package:vet45_einvoice_infrastructure/src/adapters/misa/worker_only_electronic_invoice_provider_port.dart';
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

ElectronicInvoiceProviderContextDto _context() {
  return const ElectronicInvoiceProviderContextDto(
    tenantId: 'tenant-1',
    providerConnectionId: 'conn-1',
    electronicInvoiceId: 'ei-1',
    providerInvoiceReference: 'tx-1',
    invoiceSeries: '1C25TYY',
    operationId: 'op-1',
  );
}

MeInvoiceElectronicInvoiceProviderAdapter _adapter({
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
  return MeInvoiceElectronicInvoiceProviderAdapter(
    rpcClient: SupabaseSchemaRpcClient(
      supabase: supabase,
      schema: 'einvoice',
      mapError: (error, [stackTrace]) => RpcException(error.toString()),
    ),
    clientFactory: factory,
    defaultAppId: 'app-id',
    defaultBaseUrl: MeInvoiceConfig.testBaseUrl,
    now: () => DateTime.utc(2026, 8, 31, 9),
  );
}

void main() {
  group('WorkerOnlyElectronicInvoiceProviderPort', () {
    test('throws before any HTTP-facing adapter call', () async {
      final port = WorkerOnlyElectronicInvoiceProviderPort();
      await expectLater(
        port.fetchOfficialView(_context()),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('MeInvoiceElectronicInvoiceProviderAdapter', () {
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
      'previewPublished receives transaction id and company tax code',
      () async {
        final adapter = _adapter(fakeClient: fakeClient, supabase: supabase);

        final outcome = await adapter.fetchOfficialView(_context());

        expect(fakeClient.previewPublishedCount, 1);
        expect(fakeClient.lastTransactionIds, ['tx-1']);
        expect(fakeClient.lastCompanyTaxCode, '0101234567');
        expect(outcome, isA<OfficialViewProviderSuccess>());
        final success = outcome as OfficialViewProviderSuccess;
        expect(success.viewerUrl, contains('https://'));
        expect(success.expiresAt, DateTime.utc(2026, 8, 31, 9, 5));
      },
    );

    test(
      'download receives transaction id, series query and PDF type',
      () async {
        final adapter = _adapter(fakeClient: fakeClient, supabase: supabase);

        final outcome = await adapter.downloadDocument(
          _context(),
          InvoiceDocumentType.pdf,
        );

        expect(fakeClient.downloadCount, 1);
        expect(fakeClient.lastTransactionIds, ['tx-1']);
        expect(fakeClient.lastDownloadDataType, MeInvoiceDownloadDataType.pdf);
        expect(fakeClient.lastDownloadQuery?.invoiceWithCode, isTrue);
        expect(fakeClient.lastDownloadQuery?.invoiceCalcu, isFalse);
        expect(outcome, isA<InvoiceDocumentProviderSuccess>());
      },
    );

    test('download uses XML type when requested', () async {
      final adapter = _adapter(fakeClient: fakeClient, supabase: supabase);

      await adapter.downloadDocument(_context(), InvoiceDocumentType.xml);

      expect(fakeClient.lastDownloadDataType, MeInvoiceDownloadDataType.xml);
    });

    test('empty provider document maps to DOCUMENT_UNAVAILABLE', () async {
      fakeClient.enqueueDownloadResult(
        const MeInvoiceResult.failed('meinvoice_download_empty_data'),
      );
      final adapter = _adapter(fakeClient: fakeClient, supabase: supabase);

      final outcome = await adapter.downloadDocument(
        _context(),
        InvoiceDocumentType.pdf,
      );

      expect(outcome, isA<InvoiceDocumentProviderDefiniteFailure>());
      expect(
        (outcome as InvoiceDocumentProviderDefiniteFailure).failureCode,
        'DOCUMENT_UNAVAILABLE',
      );
    });

    test('malformed document bytes map to CHECK_REQUIRED', () async {
      fakeClient.enqueueDownloadResult(
        MeInvoiceResult.ok([
          MeInvoiceInvoiceDataPublished(
            transactionId: 'tx-1',
            bytes: [1, 2, 3],
          ),
        ]),
      );
      final adapter = _adapter(fakeClient: fakeClient, supabase: supabase);

      final outcome = await adapter.downloadDocument(
        _context(),
        InvoiceDocumentType.pdf,
      );

      expect(outcome, isA<InvoiceDocumentProviderCheckRequired>());
      expect(
        (outcome as InvoiceDocumentProviderCheckRequired).safeErrorCode,
        'DOCUMENT_CONTENT_INVALID',
      );
    });

    test('provider auth rejection maps to CHECK_REQUIRED', () async {
      fakeClient.enqueuePreviewPublishedResult(
        const MeInvoiceResult.failed('missing_MISA_MEINVOICE_APP_ID'),
      );
      final adapter = _adapter(fakeClient: fakeClient, supabase: supabase);

      final outcome = await adapter.fetchOfficialView(_context());

      expect(outcome, isA<OfficialViewProviderCheckRequired>());
      expect(
        (outcome as OfficialViewProviderCheckRequired).safeErrorCode,
        'PROVIDER_AUTH_FAILED',
      );
    });

    test('transport failure throws ProviderCallAmbiguousException', () async {
      fakeClient.enqueuePreviewPublishedResult(
        const MeInvoiceResult.failed('meinvoice_5xx'),
      );
      final adapter = _adapter(fakeClient: fakeClient, supabase: supabase);

      await expectLater(
        adapter.fetchOfficialView(_context()),
        throwsA(isA<ProviderCallAmbiguousException>()),
      );
    });

    test(
      'missing tax code maps to CHECK_REQUIRED without provider call',
      () async {
        supabase.registerHandler('read_provider_credentials', (_) async {
          return [
            {
              'tax_code': '',
              'username': 'user',
              'password': 'pass',
              'base_url': MeInvoiceConfig.testBaseUrl,
            },
          ];
        });
        final adapter = _adapter(fakeClient: fakeClient, supabase: supabase);

        final outcome = await adapter.fetchOfficialView(_context());

        expect(fakeClient.previewPublishedCount, 0);
        expect(outcome, isA<OfficialViewProviderCheckRequired>());
        expect(
          (outcome as OfficialViewProviderCheckRequired).safeErrorCode,
          'PROVIDER_TAX_CODE_MISSING',
        );
      },
    );
  });

  group('MeInvoiceObservationClassifier', () {
    test('maps only allow-listed state fields into details snapshot', () {
      final outcome = MeInvoiceObservationClassifier.classify(
        result: MeInvoiceResult.ok([
          MeInvoiceInvoiceStatus(
            transactionId: 'tx-1',
            publishStatus: 1,
            eInvoiceStatus: 2,
            referenceType: 1,
            sendTaxStatus: 0,
            invoiceCode: 'OK',
            invNo: '00000001',
            invSeries: '1C25TYY',
            publishedTime: DateTime.utc(2026, 8, 31, 8),
          ),
        ]),
        providerInvoiceReference: 'tx-1',
        now: DateTime.utc(2026, 8, 31, 9),
      );

      expect(outcome, isA<ProviderObservationFound>());
      final found = outcome as ProviderObservationFound;
      expect(found.detailsSnapshot.keys, [
        'publishStatus',
        'eInvoiceStatus',
        'referenceType',
        'sendTaxStatus',
        'invoiceCode',
        'invNo',
        'invSeries',
        'publishedTime',
        'transactionId',
      ]);
      expect(found.providerStateCode, 'PS_1_ES_2');
      expect(found.safeDescription, 'PUBLISHED');
    });

    test('empty status payload maps to NOT_FOUND provider fact', () {
      final outcome = MeInvoiceObservationClassifier.classify(
        result: const MeInvoiceResult.ok(<MeInvoiceInvoiceStatus>[]),
        providerInvoiceReference: 'tx-1',
        now: DateTime.utc(2026, 8, 31, 9),
      );

      expect(outcome, isA<ProviderObservationNotFound>());
    });

    test('identity mismatch maps to MISMATCH provider fact', () {
      final outcome = MeInvoiceObservationClassifier.classify(
        result: MeInvoiceResult.ok([
          const MeInvoiceInvoiceStatus(
            transactionId: 'tx-other',
            publishStatus: 1,
          ),
        ]),
        providerInvoiceReference: 'tx-1',
        now: DateTime.utc(2026, 8, 31, 9),
      );

      expect(outcome, isA<ProviderObservationMismatch>());
    });

    test('transport failure throws ProviderCallAmbiguousException', () {
      expect(
        () => MeInvoiceObservationClassifier.classify(
          result: const MeInvoiceResult.failed('meinvoice_5xx'),
          providerInvoiceReference: 'tx-1',
          now: DateTime.utc(2026, 8, 31, 9),
        ),
        throwsA(isA<ProviderCallAmbiguousException>()),
      );
    });
  });
}
