import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_invoice_preview_gateway.dart';
import '../../commands/request_invoice_preview/request_invoice_preview_result.dart';
import 'get_invoice_preview_query.dart';

@QueryHandlerFor(GetInvoicePreviewQuery)
final class GetInvoicePreviewQueryHandler
    implements IQueryHandler<GetInvoicePreviewQuery, InvoicePreviewResultDto> {
  GetInvoicePreviewQueryHandler({
    required IInvoicePreviewGateway previewGateway,
  }) : _previewGateway = previewGateway;

  final IInvoicePreviewGateway _previewGateway;

  @override
  Future<InvoicePreviewResultDto> handle(GetInvoicePreviewQuery query) async {
    final cached = await _previewGateway.readCached(
      tenantId: query.tenantId,
      actorId: query.actorId,
      salesOrderId: query.salesOrderId,
    );

    return cached ??
        const InvoicePreviewResultDto(
          viewerRef: null,
          warnings: [],
        );
  }
}
