import 'package:vet45_einvoice_domain/domain.dart';

import '../../issuance/commands/request_invoice_preview/request_invoice_preview_result.dart';
import '../../ports/i_invoice_preview_gateway.dart';

final class FakeInvoicePreviewGateway implements IInvoicePreviewGateway {
  FakeInvoicePreviewGateway({required this.requestId, this.cached});

  final String requestId;
  final InvoicePreviewResultDto? cached;
  String? enqueuedFor;
  final List<
    ({
      String requestId,
      String salesOrderId,
      String status,
      String? viewerRef,
      String? failureCode,
      String? failureMessage,
      FailureSource? failureSource,
    })
  >
  stored = [];

  @override
  Future<String> persistRequestAndEnqueue({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
    required int expectedOrderVersion,
  }) async {
    enqueuedFor = salesOrderId;
    return requestId;
  }

  @override
  Future<InvoicePreviewResultDto?> readCached({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
  }) async => cached;

  @override
  Future<void> storeResult({
    required String tenantId,
    required String salesOrderId,
    required String requestId,
    required String status,
    String? viewerRef,
    String? failureCode,
    String? failureMessage,
    FailureSource? failureSource,
  }) async {
    stored.add((
      requestId: requestId,
      salesOrderId: salesOrderId,
      status: status,
      viewerRef: viewerRef,
      failureCode: failureCode,
      failureMessage: failureMessage,
      failureSource: failureSource,
    ));
  }
}
