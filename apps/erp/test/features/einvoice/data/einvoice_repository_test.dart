import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/einvoice/data/einvoice_errors.dart';
import 'package:erp/features/einvoice/data/einvoice_processor_trigger.dart';
import 'package:erp/features/einvoice/data/einvoice_repository.dart';
import 'package:erp/features/einvoice/data/invoice_document_signed_urls.dart';
import 'package:erp/features/einvoice/data/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

import 'einvoice_parity_expectations.dart';

class _Call {
  _Call(this.schema, this.fn, this.params);
  final String schema;
  final String fn;
  final Map<String, dynamic>? params;
}

class _RecordingRpc implements SupabaseRpc {
  final calls = <_Call>[];
  Object? result;
  Object? Function(String schema, String fn, Map<String, dynamic>? params)? onCall;
  Object? error;

  @override
  Future<dynamic> call(String schema, String fn, {Map<String, dynamic>? params}) async {
    calls.add(_Call(schema, fn, params));
    final e = error;
    if (e != null) {
      if (e is PostgrestException) throw AppException.from(e);
      if (e is AppException) throw e;
      throw AppException.from(e);
    }
    if (onCall != null) {
      return onCall!(schema, fn, params);
    }
    return result;
  }

  @override
  Future<List<Map<String, dynamic>>> rows(
    String schema,
    String fn, {
    Map<String, dynamic>? params = const {},
  }) async {
    final raw = await call(schema, fn, params: params);
    if (raw == null) return const [];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
    }
    if (raw is Map) {
      return [Map<String, dynamic>.from(raw)];
    }
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DummyFunctions implements FunctionsClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingTrigger extends EInvoiceProcessorTrigger {
  _RecordingTrigger() : super(_DummyFunctions());
  final kicks = <String>[];

  @override
  void kick(String tenantId) {
    kicks.add(tenantId);
  }
}

class _DummyStorageClient implements SupabaseStorageClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSignedUrls extends InvoiceDocumentSignedUrls {
  _FakeSignedUrls() : super(storage: _DummyStorageClient());

  String? urlToReturn = 'https://signed.url/doc';
  DateTime? expiresAtToReturn;

  @override
  Future<String?> tryCreate(String ref) async => urlToReturn;

  @override
  DateTime leaseExpiresAt({DateTime? now}) =>
      expiresAtToReturn ?? (now ?? DateTime.utc(2026, 11, 8, 12, 5, 0));
}

void main() {
  const tenant = parityTenantId;
  const actor = parityActorId;
  const order = parityOrderId;
  const idempotencyKey = parityIdempotencyKey;

  late _RecordingRpc rpc;
  late _RecordingTrigger trigger;
  late _FakeSignedUrls signedUrls;
  late EInvoiceRepository repository;

  setUp(() {
    rpc = _RecordingRpc();
    trigger = _RecordingTrigger();
    signedUrls = _FakeSignedUrls();
    repository = EInvoiceRepository(
      rpc: rpc,
      trigger: trigger,
      signedUrls: signedUrls,
      tenantId: () async => tenant,
      actorId: () async => actor,
    );
  });

  test('kick_after_write_rpcs: write operations kick after successful RPC', () async {
    // 1. requestPreview (when ready)
    rpc.onCall = (schema, fn, params) {
      if (fn == 'get_issuance_readiness') return [sampleReadinessReadyJson()];
      if (fn == 'request_invoice_preview') return [sampleInvoicePreviewResultJson()];
      return [];
    };
    await repository.requestPreview(salesOrderId: order, expectedOrderVersion: 1);
    expect(trigger.kicks, [tenant]);

    // 2. issue
    trigger.kicks.clear();
    rpc.onCall = null;
    rpc.result = [sampleIssueInvoiceResultJson()];
    await repository.issue(salesOrderId: order, sourceVersion: '1', idempotencyKey: idempotencyKey);
    expect(trigger.kicks, [tenant]);

    // 3. retry
    trigger.kicks.clear();
    rpc.result = [sampleIssueInvoiceResultJson()];
    await repository.retry(salesOrderId: order, expectedOrderVersion: 1, idempotencyKey: idempotencyKey);
    expect(trigger.kicks, [tenant]);

    // 4. requestOfficialView
    trigger.kicks.clear();
    rpc.result = [sampleOfficialViewJson()];
    await repository.requestOfficialView(order);
    expect(trigger.kicks, [tenant]);

    // 5. requestDocument
    trigger.kicks.clear();
    rpc.result = [sampleDocumentRetrievalJson()];
    await repository.requestDocument(salesOrderId: order, documentType: InvoiceDocumentType.pdf);
    expect(trigger.kicks, [tenant]);

    // 6. send
    trigger.kicks.clear();
    rpc.result = [sampleSendInvoiceResultJson()];
    await repository.send(salesOrderId: order, recipientEmail: 'a@b.vn', idempotencyKey: idempotencyKey);
    expect(trigger.kicks, [tenant]);
  });

  test('no_kick_on_reads: 8 read queries do not trigger kick', () async {
    rpc.result = [sampleOrderInvoiceProjectionJson()];
    await repository.getProjection(order);

    rpc.result = [sampleReadinessReadyJson()];
    await repository.getReadiness(order);

    rpc.result = [sampleIssuanceAttemptStatusJson()];
    await repository.getAttemptStatus(order);

    rpc.result = [sampleInvoicePreviewResultJson()];
    await repository.getPreview(order);

    rpc.result = [sampleDetailJson()];
    await repository.getDetail(order);

    rpc.result = [sampleDocumentsJson()];
    await repository.getDocuments(order);

    rpc.result = [sampleSendSheetContextJson()];
    await repository.getSendSheetContext(order);

    rpc.result = [sampleHistoryJson()];
    await repository.getDeliveryHistory(order);

    expect(trigger.kicks, isEmpty);
  });

  test('preview_config_not_ready_blocks_rpc (D5): missing template throws CONFIG_NOT_READY before preview rpc', () async {
    rpc.onCall = (schema, fn, params) {
      if (fn == 'get_issuance_readiness') return [sampleReadinessMissingTemplateJson()];
      return [];
    };

    await expectLater(
      () => repository.requestPreview(salesOrderId: order, expectedOrderVersion: 1),
      throwsA(isA<AppException>().having((e) => e.code, 'code', 'CONFIG_NOT_READY')),
    );
    expect(rpc.calls.length, 1);
    expect(rpc.calls.first.fn, 'get_issuance_readiness');
    expect(trigger.kicks, isEmpty);
  });

  test('preview_buyer_blocks_rpc: missing buyer address throws ISSUANCE_NOT_READY', () async {
    rpc.onCall = (schema, fn, params) {
      if (fn == 'get_issuance_readiness') return [sampleReadinessOrgMissingAddressJson()];
      return [];
    };

    await expectLater(
      () => repository.requestPreview(salesOrderId: order, expectedOrderVersion: 1),
      throwsA(
        isA<AppException>()
            .having((e) => e.code, 'code', 'ISSUANCE_NOT_READY')
            .having((e) => e.serverMessage, 'serverMessage', 'Không đủ điều kiện xem trước')
            .having((e) => e.details?['blockers'], 'blockers', contains('BUYER_ADDRESS_REQUIRED')),
      ),
    );
    expect(rpc.calls.length, 1);
    expect(rpc.calls.first.fn, 'get_issuance_readiness');
    expect(trigger.kicks, isEmpty);
  });

  test('preview_tax_code_only_still_requests_preview: missing tax code only still requests preview', () async {
    rpc.onCall = (schema, fn, params) {
      if (fn == 'get_issuance_readiness') return [sampleReadinessOrgMissingTaxJson()];
      if (fn == 'request_invoice_preview') return [sampleInvoicePreviewResultJson()];
      return [];
    };

    final result = await repository.requestPreview(salesOrderId: order, expectedOrderVersion: 1);
    expect(rpc.calls.length, 2);
    expect(rpc.calls[0].fn, 'get_issuance_readiness');
    expect(rpc.calls[1].fn, 'request_invoice_preview');
    expect(result.viewerRef, isNull);
    expect(trigger.kicks, [tenant]);
  });

  test('preview_ok_returns_warnings: ready with warnings calls 2 RPCs and returns warnings', () async {
    rpc.onCall = (schema, fn, params) {
      if (fn == 'get_issuance_readiness') return [sampleReadinessReadyJson()];
      if (fn == 'request_invoice_preview') return [sampleInvoicePreviewResultJson()];
      return [];
    };

    final result = await repository.requestPreview(salesOrderId: order, expectedOrderVersion: 1);
    expect(rpc.calls.length, 2);
    expect(rpc.calls[0].fn, 'get_issuance_readiness');
    expect(rpc.calls[1].fn, 'request_invoice_preview');
    expect(result.viewerRef, isNull);
    expect(result.warnings, isEmpty);
    expect(trigger.kicks, [tenant]);
  });

  test('preview_empty_dto (D4): getPreview with [] returns empty DTO without error', () async {
    rpc.result = <Map<String, dynamic>>[];

    final result = await repository.getPreview(order);
    expect(result.viewerRef, isNull);
    expect(result.warnings, isEmpty);
  });

  test('issue_ack_default_false: issue with null acknowledgeWarnings defaults to false', () async {
    rpc.result = [sampleIssueInvoiceResultJson()];

    await repository.issue(
      salesOrderId: order,
      sourceVersion: '1',
      idempotencyKey: idempotencyKey,
      acknowledgeWarnings: null,
    );
    expect(rpc.calls.single.params?['p_acknowledge_warnings'], false);
  });

  test('send_email_untrimmed: send recipient email is passed without trimming', () async {
    rpc.result = [sampleSendInvoiceResultJson()];

    await repository.send(
      salesOrderId: order,
      recipientEmail: ' a@b.vn ',
      idempotencyKey: idempotencyKey,
    );
    expect(rpc.calls.single.params?['p_recipient_email'], ' a@b.vn ');
  });

  test('document_signed_url_ok (D10): requestDocument with available status and valid fileRef signs url', () async {
    rpc.result = [
      {
        'request_id': 'op-1',
        'status': 'AVAILABLE',
        'storage_reference': 'storage/path/inv.pdf',
        'checksum': 'sha256:abc',
      }
    ];
    signedUrls.urlToReturn = 'https://signed.url/inv.pdf';

    final result = await repository.requestDocument(
      salesOrderId: order,
      documentType: InvoiceDocumentType.pdf,
    );
    expect(result.status, InvoiceDocumentStatus.available);
    expect(result.downloadUrl, 'https://signed.url/inv.pdf');
  });

  test('document_signed_url_fail_check_required: failed signed url sets status to checkRequired', () async {
    rpc.result = [
      {
        'request_id': 'op-1',
        'status': 'AVAILABLE',
        'storage_reference': 'storage/path/inv.pdf',
        'checksum': 'sha256:abc',
      }
    ];
    signedUrls.urlToReturn = null;

    final result = await repository.requestDocument(
      salesOrderId: order,
      documentType: InvoiceDocumentType.pdf,
    );
    expect(result.status, InvoiceDocumentStatus.checkRequired);
    expect(result.downloadUrl, isNull);
  });

  test('documents_aggregate_status: aggregates status and sets lease expiration', () async {
    final fixedExpiry = DateTime.utc(2026, 11, 8, 12, 10, 0);
    signedUrls.expiresAtToReturn = fixedExpiry;

    // Case 1: PDF AVAILABLE (url error) + XML PENDING -> pdf.status == checkRequired, retrievalStatus == checkRequired
    signedUrls.urlToReturn = null;
    rpc.result = [
      {
        'pdf_available': true,
        'xml_available': false,
        'retrieval_status': 'PENDING',
        'pdf_operation_id': 'op-pdf',
        'pdf_status': 'AVAILABLE',
        'pdf_storage_reference': 'ref-pdf',
        'pdf_checksum': 'c-pdf',
        'pdf_failure_code': null,
        'xml_operation_id': 'op-xml',
        'xml_status': 'PENDING',
        'xml_storage_reference': null,
        'xml_checksum': null,
        'xml_failure_code': null,
      }
    ];
    var docs = await repository.getDocuments(order);
    expect(docs.pdf?.status, InvoiceDocumentStatus.checkRequired);
    expect(docs.retrievalStatus, InvoiceDocumentStatus.checkRequired);

    // Case 2: PDF AVAILABLE (url ok) + XML PENDING -> retrievalStatus == pending, pdf has expiresAt
    signedUrls.urlToReturn = 'https://signed.url/pdf';
    docs = await repository.getDocuments(order);
    expect(docs.pdf?.status, InvoiceDocumentStatus.available);
    expect(docs.pdf?.downloadUrl, 'https://signed.url/pdf');
    expect(docs.pdf?.expiresAt, fixedExpiry);
    expect(docs.retrievalStatus, InvoiceDocumentStatus.pending);
  });

  test('no_kick_when_rpc_fails: issue fails with ISSUANCE_NOT_READY does not kick', () async {
    rpc.error = const PostgrestException(
      message: 'ISSUANCE_NOT_READY: {"details":{"blockers":["BUYER_TAX_CODE_REQUIRED"]}}',
    );

    await expectLater(
      () => repository.issue(salesOrderId: order, sourceVersion: '1', idempotencyKey: idempotencyKey),
      throwsA(
        isA<AppException>()
            .having((e) => e.code, 'code', 'ISSUANCE_NOT_READY')
            .having((e) => e.details?['blockers'], 'blockers', ['BUYER_TAX_CODE_REQUIRED']),
      ),
    );
    expect(trigger.kicks, isEmpty);
  });

  test('empty_rows_is_system_error: getProjection with [] throws SYSTEM_ERROR', () async {
    rpc.result = <Map<String, dynamic>>[];

    await expectLater(
      () => repository.getProjection(order),
      throwsA(isA<AppException>().having((e) => e.code, 'code', EInvoiceErrorCodes.systemError)),
    );
  });

  test('rule_blocks_before_rpc: validation fails before RPC call', () async {
    // issue with non-uuid key
    await expectLater(
      () => repository.issue(salesOrderId: order, sourceVersion: '1', idempotencyKey: 'abc'),
      throwsA(isA<AppException>().having((e) => e.code, 'code', EInvoiceErrorCodes.validationError)),
    );
    expect(rpc.calls, isEmpty);

    // send with invalid email
    await expectLater(
      () => repository.send(salesOrderId: order, recipientEmail: 'a@b', idempotencyKey: idempotencyKey),
      throwsA(isA<AppException>().having((e) => e.code, 'code', EInvoiceErrorCodes.validationError)),
    );
    expect(rpc.calls, isEmpty);
  });
}
