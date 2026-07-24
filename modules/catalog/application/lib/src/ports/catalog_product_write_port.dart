import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_catalog_application/src/ports/i_catalog_read_gateway.dart';
import 'package:vet45_catalog_application/src/ports/i_product_write_port.dart';
import 'package:vet45_catalog_application/src/product/shared/product_write_model_mapper.dart';

final class CatalogProductWritePort implements IProductWritePort {
  CatalogProductWritePort({required ICatalogReadGateway readGateway}) : _readGateway = readGateway;

  final ICatalogReadGateway _readGateway;

  @override
  Future<Product?> load({
    required String tenantId,
    required String productId,
  }) async {
    final model = await _readGateway.loadControlCenter(
      tenantId: tenantId,
      productId: productId,
    );
    if (model == null) {
      return null;
    }
    return ProductWriteModelMapper.fromControlCenter(
      tenantId: tenantId,
      model: model,
    );
  }
}
