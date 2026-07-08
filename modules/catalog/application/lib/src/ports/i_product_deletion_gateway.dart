import '../lifecycle/check_product_deletion_eligibility_query.dart';
import '../lifecycle/product_deletion_eligibility_dto.dart';

abstract interface class IProductDeletionGateway {
  Future<ProductDeletionEligibilityDto> checkDeletionEligibility(
    CheckProductDeletionEligibilityQuery query,
  );
}
