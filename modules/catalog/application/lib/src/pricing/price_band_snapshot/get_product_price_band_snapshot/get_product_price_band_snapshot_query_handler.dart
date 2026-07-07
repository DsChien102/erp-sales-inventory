import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_product_price_band_gateway.dart';
import '../product_price_band_snapshot_dto.dart';
import '../product_price_band_snapshot_item_dto.dart';
import 'get_product_price_band_snapshot_query.dart';
import 'get_product_price_band_snapshot_query_validator.dart';

@QueryHandlerFor(GetProductPriceBandSnapshotQuery)
final class GetProductPriceBandSnapshotQueryHandler
    implements
        IQueryHandler<
          GetProductPriceBandSnapshotQuery,
          ProductPriceBandSnapshotDto
        > {
  GetProductPriceBandSnapshotQueryHandler({
    required IProductPriceBandGateway priceBandGateway,
    GetProductPriceBandSnapshotQueryValidator? validator,
  }) : _priceBandGateway = priceBandGateway,
       _validator = validator ?? GetProductPriceBandSnapshotQueryValidator();

  final IProductPriceBandGateway _priceBandGateway;
  final GetProductPriceBandSnapshotQueryValidator _validator;

  @override
  Future<ProductPriceBandSnapshotDto> handle(
    GetProductPriceBandSnapshotQuery query,
  ) async {
    await _validator.validate(query);
    final snapshot = await _priceBandGateway.getPriceBandSnapshot(
      tenantId: query.tenantId,
      items: query.items,
    );
    final capturedAt = DateTime.now().toUtc();
    return ProductPriceBandSnapshotDto(
      items: snapshot.items
          .map(
            (item) => ProductPriceBandSnapshotItemDto(
              productId: item.productId,
              productUnitId: item.productUnitId,
              unitName: item.unitName,
              currency: item.currency,
              listPrice: item.listPrice,
              listPriceMissing: item.listPriceMissing,
              floorPrice: item.floorPrice,
              floorPriceMissing: item.floorPriceMissing,
              floorPriceHidden: item.floorPriceHidden,
              isUnitActive: item.isUnitActive,
              productBusinessStatus: item.productBusinessStatus,
              capturedAt: capturedAt,
            ),
          )
          .toList(growable: false),
    );
  }
}
