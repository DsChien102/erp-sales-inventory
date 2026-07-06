import 'package:vet45_shared_application/application.dart';

import '../ports/i_product_readiness_read_port.dart';
import 'get_product_readiness_query.dart';
import 'product_readiness_view_dto.dart';

@QueryHandlerFor(GetProductReadinessQuery)
final class GetProductReadinessQueryHandler
    implements
        IQueryHandler<GetProductReadinessQuery, ProductReadinessViewDto> {
  GetProductReadinessQueryHandler({
    required IProductReadinessReadPort readinessReadPort,
  }) : _readinessReadPort = readinessReadPort;

  final IProductReadinessReadPort _readinessReadPort;

  @override
  Future<ProductReadinessViewDto> handle(GetProductReadinessQuery query) async {
    return _readinessReadPort.getByProductId(
      tenantId: query.tenantId,
      productId: query.productId,
    );
  }
}
