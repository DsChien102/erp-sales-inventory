import 'package:vet45_catalog_application/src/product/queries/check_product_deletion_eligibility/check_product_deletion_eligibility_query.dart';
import 'package:vet45_catalog_application/src/product/queries/check_product_deletion_eligibility/product_deletion_eligibility_dto.dart';

abstract interface class IProductDeletionGateway {
  Future<ProductDeletionEligibilityDto> checkDeletionEligibility(
    CheckProductDeletionEligibilityQuery query,
  );
}
