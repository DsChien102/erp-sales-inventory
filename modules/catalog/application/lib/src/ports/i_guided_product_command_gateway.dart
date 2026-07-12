import 'package:vet45_catalog_application/src/product/commands/create_guided_product/create_guided_product_command.dart';
import 'package:vet45_catalog_application/src/product/commands/create_guided_product/create_guided_product_result.dart';

abstract interface class IGuidedProductCommandGateway {
  Future<CreateGuidedProductResult> createGuidedProduct(
    CreateGuidedProductCommand command,
  );
}
