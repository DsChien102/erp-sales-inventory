import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_electronic_invoice_read_gateway.dart';
import '../../shared/provider_observation_dto.dart';
import 'get_latest_provider_observation_query.dart';

@QueryHandlerFor(GetLatestProviderObservationQuery)
final class GetLatestProviderObservationQueryHandler
    implements IQueryHandler<GetLatestProviderObservationQuery, ProviderObservationDto?> {
  GetLatestProviderObservationQueryHandler({
    required IElectronicInvoiceReadGateway gateway,
  }) : _gateway = gateway;

  final IElectronicInvoiceReadGateway _gateway;

  @override
  Future<ProviderObservationDto?> handle(
    GetLatestProviderObservationQuery query,
  ) => _gateway.getLatestObservation(
    tenantId: query.tenantId,
    actorId: query.actorId,
    salesOrderId: query.salesOrderId,
  );
}
