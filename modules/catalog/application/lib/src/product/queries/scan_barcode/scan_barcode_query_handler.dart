import 'package:vet45_shared_application/application.dart';

import 'package:vet45_catalog_application/src/ports/i_catalog_read_gateway.dart';
import 'package:vet45_catalog_application/src/product/queries/search_products/product_list_item_dto.dart';
import 'scan_barcode_query.dart';

@QueryHandlerFor(ScanBarcodeQuery)
final class ScanBarcodeQueryHandler
    implements IQueryHandler<ScanBarcodeQuery, ProductListItemDto?> {
  ScanBarcodeQueryHandler({
    required ICatalogReadGateway readGateway,
  }) : _readGateway = readGateway;

  final ICatalogReadGateway _readGateway;

  @override
  Future<ProductListItemDto?> handle(ScanBarcodeQuery query) {
    final barcode = query.barcode.trim();
    if (barcode.isEmpty) {
      return Future.value(null);
    }

    return _readGateway.findByBarcode(
      tenantId: query.tenantId,
      barcode: barcode,
    );
  }
}
