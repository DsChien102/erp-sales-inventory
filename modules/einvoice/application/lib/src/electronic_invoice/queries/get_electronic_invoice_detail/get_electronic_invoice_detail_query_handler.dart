import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_electronic_invoice_read_gateway.dart';
import 'electronic_invoice_detail_dto.dart';
import 'get_electronic_invoice_detail_query.dart';

@QueryHandlerFor(GetElectronicInvoiceDetailQuery)
final class GetElectronicInvoiceDetailQueryHandler
    implements IQueryHandler<GetElectronicInvoiceDetailQuery, ElectronicInvoiceDetailDto> {
  GetElectronicInvoiceDetailQueryHandler({
    required IElectronicInvoiceReadGateway gateway,
  }) : _gateway = gateway;

  final IElectronicInvoiceReadGateway _gateway;

  @override
  Future<ElectronicInvoiceDetailDto> handle(
    GetElectronicInvoiceDetailQuery query,
  ) => _gateway.getDetail(
    tenantId: query.tenantId,
    actorId: query.actorId,
    salesOrderId: query.salesOrderId,
  );
}
