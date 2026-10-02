import 'package:test/test.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_einvoice_infrastructure/src/data_access/electronic_invoice_rpc_mapper.dart';
import 'package:vet45_einvoice_infrastructure/src/data_access/supabase_electronic_invoice_command_gateway.dart';
import 'package:vet45_einvoice_infrastructure/src/data_access/supabase_electronic_invoice_read_gateway.dart';
import 'package:vet45_einvoice_infrastructure/src/storage/invoice_document_signed_url_resolver.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../support/fake_invoice_document_storage_supabase.dart';
import '../support/fake_einvoice_rpc_supabase.dart';

SupabaseSchemaRpcClient _rpcClient(FakeEinvoiceRpcSupabase supabase) {
  return SupabaseSchemaRpcClient(
    supabase: supabase,
    schema: 'einvoice',
    mapError: (error, [stackTrace]) => RpcException(error.toString()),
  );
}

InvoiceDocumentSignedUrlResolver _signedUrlResolver() {
  return InvoiceDocumentSignedUrlResolver(
    supabase: FakeInvoiceDocumentStorageSupabase(),
  );
}

void main() {
  group('SupabaseElectronicInvoiceCommandGateway', () {
    test('requestOfficialView sends exact scoped params', () async {
      final supabase = FakeEinvoiceRpcSupabase()
        ..registerHandler('request_official_invoice_view', (params) async {
          expect(params, {
            'p_tenant_id': 'tenant-1',
            'p_actor_id': 'actor-1',
            'p_sales_order_id': 'order-1',
          });
          return [
            {
              'operation_id': 'op-1',
              'status': 'PENDING',
              'viewer_url': null,
              'viewer_token': null,
              'expires_at': null,
            },
          ];
        });
      final gateway = SupabaseElectronicInvoiceCommandGateway(
        rpcClient: _rpcClient(supabase),
        signedUrlResolver: _signedUrlResolver(),
      );

      final result = await gateway.requestOfficialView(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        salesOrderId: 'order-1',
      );

      expect(
        supabase.calls.single.functionName,
        'request_official_invoice_view',
      );
      expect(result.operationId, 'op-1');
      expect(result.status, InvoiceDocumentStatus.pending);
    });

    test('maps NOT_FOUND to blocked code', () async {
      final supabase = FakeEinvoiceRpcSupabase()
        ..registerHandler('request_official_invoice_view', (_) async {
          throw RpcException('NOT_FOUND: sales order not found');
        });
      final gateway = SupabaseElectronicInvoiceCommandGateway(
        rpcClient: _rpcClient(supabase),
        signedUrlResolver: _signedUrlResolver(),
      );

      await expectLater(
        gateway.requestOfficialView(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-1',
        ),
        throwsA(
          isA<EInvoiceBlockedException>().having(
            (error) => error.code,
            'code',
            EInvoiceBlockedCodes.notFound,
          ),
        ),
      );
    });

    test('loadOfficialViewContext maps worker context row', () async {
      final supabase = FakeEinvoiceRpcSupabase()
        ..registerHandler('load_official_view_operation_context', (
          params,
        ) async {
          expect(params, {
            'p_tenant_id': 'tenant-1',
            'p_electronic_invoice_id': 'invoice-1',
            'p_request_id': 'req-1',
          });
          return [
            {
              'tenant_id': 'tenant-1',
              'electronic_invoice_id': 'invoice-1',
              'request_id': 'req-1',
              'status': 'PENDING',
              'provider_connection_id': 'conn-1',
              'provider_invoice_reference': 'prov-ref',
              'invoice_series': 'AA/26E',
            },
          ];
        });
      final gateway = SupabaseElectronicInvoiceCommandGateway(
        rpcClient: _rpcClient(supabase),
        signedUrlResolver: _signedUrlResolver(),
      );

      final context = await gateway.loadOfficialViewContext(
        tenantId: 'tenant-1',
        electronicInvoiceId: 'invoice-1',
        requestId: 'req-1',
      );

      expect(context, isNotNull);
      expect(context!.requestId, 'req-1');
      expect(context.electronicInvoiceId, 'invoice-1');
      expect(context.invoiceSeries, 'AA/26E');
    });

    test('recordOfficialViewResult sends frozen worker params', () async {
      final supabase = FakeEinvoiceRpcSupabase()
        ..registerHandler('record_official_invoice_view_result', (
          params,
        ) async {
          final normalized = params ?? <String, dynamic>{};
          expect(normalized['p_tenant_id'], 'tenant-1');
          expect(normalized['p_electronic_invoice_id'], 'invoice-1');
          expect(normalized['p_request_id'], 'req-1');
          expect(normalized['p_status'], 'AVAILABLE');
          expect(normalized['p_failure_source'], isNull);
          expect(normalized['p_viewer_url'], 'https://viewer.example');
          return [
            {
              'operation_id': 'op-1',
              'status': 'AVAILABLE',
              'viewer_url': 'https://viewer.example',
              'viewer_token': 'token',
              'expires_at': '2030-01-01T00:00:00.000Z',
            },
          ];
        });
      final gateway = SupabaseElectronicInvoiceCommandGateway(
        rpcClient: _rpcClient(supabase),
        signedUrlResolver: _signedUrlResolver(),
      );

      await gateway.recordOfficialViewResult(
        OfficialViewResultRecord(
          tenantId: 'tenant-1',
          electronicInvoiceId: 'invoice-1',
          requestId: 'req-1',
          status: InvoiceDocumentStatus.available,
          viewerUrl: 'https://viewer.example',
        ),
      );

      expect(
        supabase.calls.single.functionName,
        'record_official_invoice_view_result',
      );
    });
  });

  group('SupabaseElectronicInvoiceReadGateway', () {
    test('getDetail sends scoped params and maps detail row', () async {
      final supabase = FakeEinvoiceRpcSupabase()
        ..registerHandler('get_electronic_invoice_detail', (params) async {
          expect(params, {
            'p_tenant_id': 'tenant-1',
            'p_actor_id': 'actor-1',
            'p_sales_order_id': 'order-1',
          });
          return [
            {
              'electronic_invoice_id': 'invoice-1',
              'sales_order_id': 'order-1',
              'invoice_number': '00000001',
              'provider_ref': 'prov-ref',
              'issued_at': '2026-01-15T10:00:00.000Z',
              'official_view_operation_id': 'op-1',
              'official_view_status': 'AVAILABLE',
              'official_viewer_url': 'https://viewer.example',
              'official_viewer_token': 'token',
              'official_viewer_expires_at': '2030-01-01T00:00:00.000Z',
              'official_view_failure_code': null,
            },
          ];
        });
      final gateway = SupabaseElectronicInvoiceReadGateway(
        rpcClient: _rpcClient(supabase),
        signedUrlResolver: _signedUrlResolver(),
      );

      final detail = await gateway.getDetail(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        salesOrderId: 'order-1',
      );

      expect(detail.electronicInvoiceId, 'invoice-1');
      expect(detail.invoiceNumber, '00000001');
      expect(detail.officialViewStatus, InvoiceDocumentStatus.available);
      expect(detail.officialViewerUrl, 'https://viewer.example');
      expect(detail.officialViewFailureCode, isNull);
    });

    test('getDocuments signs AVAILABLE storage references', () async {
      final supabase = FakeEinvoiceRpcSupabase()
        ..registerHandler('get_invoice_documents', (params) async {
          expect(params, {
            'p_tenant_id': 'tenant-1',
            'p_actor_id': 'actor-1',
            'p_sales_order_id': 'order-1',
          });
          return [
            {
              'pdf_available': true,
              'xml_available': false,
              'retrieval_status': 'AVAILABLE',
              'pdf_operation_id': 'op-pdf',
              'pdf_status': 'AVAILABLE',
              'pdf_storage_reference': 'tenant-1/invoice-1/pdf/v1/a.pdf',
              'pdf_checksum': 'checksum',
              'pdf_failure_code': null,
              'xml_operation_id': null,
              'xml_status': null,
              'xml_storage_reference': null,
              'xml_checksum': null,
              'xml_failure_code': null,
            },
          ];
        });
      final gateway = SupabaseElectronicInvoiceReadGateway(
        rpcClient: _rpcClient(supabase),
        signedUrlResolver: _signedUrlResolver(),
      );

      final documents = await gateway.getDocuments(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        salesOrderId: 'order-1',
      );

      expect(documents.pdf?.downloadUrl, contains('ttl=300'));
      expect(documents.pdf?.status, InvoiceDocumentStatus.available);
    });
  });

  group('SupabaseElectronicInvoiceCommandGateway documents', () {
    test(
      'requestDocument sends frozen params and signs AVAILABLE rows',
      () async {
        final supabase = FakeEinvoiceRpcSupabase()
          ..registerHandler('request_invoice_document', (params) async {
            expect(params, {
              'p_tenant_id': 'tenant-1',
              'p_actor_id': 'actor-1',
              'p_sales_order_id': 'order-1',
              'p_document_type': 'PDF',
            });
            return [
              {
                'request_id': 'op-pdf',
                'status': 'AVAILABLE',
                'storage_reference': 'tenant-1/invoice-1/pdf/v1/a.pdf',
                'checksum': 'checksum',
              },
            ];
          });
        final gateway = SupabaseElectronicInvoiceCommandGateway(
          rpcClient: _rpcClient(supabase),
          signedUrlResolver: _signedUrlResolver(),
        );

        final result = await gateway.requestDocument(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          salesOrderId: 'order-1',
          documentType: InvoiceDocumentType.pdf,
        );

        expect(result.downloadUrl, contains('ttl=300'));
        expect(result.fileRef, 'tenant-1/invoice-1/pdf/v1/a.pdf');
      },
    );
  });

  group('ElectronicInvoiceRpcMapper', () {
    test('ignores viewer fields when AVAILABLE is expired', () {
      final dto = ElectronicInvoiceRpcMapper.officialViewFromRow({
        'operation_id': 'op-1',
        'status': 'AVAILABLE',
        'viewer_url': 'https://viewer.example',
        'viewer_token': 'token',
        'expires_at': '2020-01-01T00:00:00.000Z',
      });

      expect(dto.status, InvoiceDocumentStatus.available);
      expect(dto.viewerUrl, isNull);
      expect(dto.token, isNull);
      expect(dto.expiresAt, isNull);
    });

    test('rejects unknown document status', () {
      expect(
        () => ElectronicInvoiceRpcMapper.mapDocumentStatus('UNKNOWN'),
        throwsA(isA<RpcException>()),
      );
    });
  });
}
