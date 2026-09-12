import 'package:vet45_catalog_application/src/ports/i_catalog_sales_read_gateway.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/sellable_product_dto.dart';
import 'resolve_sellable_barcode_query.dart';
import 'resolve_sellable_barcode_query_validator.dart';

@QueryHandlerFor(ResolveSellableBarcodeQuery)
final class ResolveSellableBarcodeQueryHandler
    implements IQueryHandler<ResolveSellableBarcodeQuery, List<SellableProductDto>> {
  ResolveSellableBarcodeQueryHandler({
    required ICatalogSalesReadGateway readGateway,
    required ResolveSellableBarcodeQueryValidator validator,
  }) : _readGateway = readGateway,
       _validator = validator;

  final ICatalogSalesReadGateway _readGateway;
  final ResolveSellableBarcodeQueryValidator _validator;

  @override
  Future<List<SellableProductDto>> handle(
    ResolveSellableBarcodeQuery query,
  ) async {
    await _validator.validate(query);
    return _readGateway.resolveSellableBarcode(
      tenantId: query.tenantId,
      storeId: query.storeId,
      barcode: query.barcode.trim(),
    );
  }
}
