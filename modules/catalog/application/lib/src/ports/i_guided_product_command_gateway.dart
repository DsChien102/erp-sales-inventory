import '../guided_create/create_guided_product_command.dart';
import '../guided_create/create_guided_product_result.dart';

abstract interface class IGuidedProductCommandGateway {
  Future<CreateGuidedProductResult> createGuidedProduct(
    CreateGuidedProductCommand command,
  );
}
