import 'package:vet45_shared_application/application.dart';

import '../ports/i_product_readiness_read_port.dart';
import 'get_product_stock_history_query.dart';
import 'get_product_stock_history_query_validator.dart';
import 'ports/i_product_stock_read_port.dart';
import 'product_stock_history_dto.dart';
import 'product_stock_movement_dto.dart';

@QueryHandlerFor(GetProductStockHistoryQuery)
final class GetProductStockHistoryQueryHandler
    implements IQueryHandler<GetProductStockHistoryQuery, ProductStockHistoryDto> {
  GetProductStockHistoryQueryHandler({
    required IProductStockReadPort stockReadPort,
    required IProductReadinessReadPort readinessReadPort,
    GetProductStockHistoryQueryValidator? validator,
  }) : _stockReadPort = stockReadPort,
       _readinessReadPort = readinessReadPort,
       _validator = validator ?? GetProductStockHistoryQueryValidator();

  final IProductStockReadPort _stockReadPort;
  final IProductReadinessReadPort _readinessReadPort;
  final GetProductStockHistoryQueryValidator _validator;

  @override
  Future<ProductStockHistoryDto> handle(GetProductStockHistoryQuery query) async {
    await _validator.validate(query);
    final facts = await _readinessReadPort.loadFacts(
      tenantId: query.tenantId,
      productId: query.productId,
    );
    if (facts == null) {
      throw ApplicationException('Product not found');
    }
    if (facts.stockMode.isAdvanced) {
      return ProductStockHistoryDto(
        productId: query.productId,
        isHistoricalBasicOnly: true,
        movements: const [],
      );
    }
    final rows = await _stockReadPort.listMovements(
      tenantId: query.tenantId,
      productId: query.productId,
      limit: query.limit,
    );
    return ProductStockHistoryDto(
      productId: query.productId,
      isHistoricalBasicOnly: true,
      movements: rows
          .map(
            (row) => ProductStockMovementDto(
              id: row.id,
              occurredAt: row.occurredAt,
              actorDisplayName: row.actorDisplayName,
              movementType: row.movementType,
              quantityBefore: row.quantityBefore,
              quantityAfter: row.quantityAfter,
              delta: row.delta,
              reason: row.reason,
            ),
          )
          .toList(growable: false),
    );
  }
}
