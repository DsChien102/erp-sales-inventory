import 'package:vet45_shared_application/application.dart';

import '../ports/i_product_deletion_gateway.dart';
import 'check_product_deletion_eligibility_query.dart';
import 'check_product_deletion_eligibility_query_validator.dart';
import 'product_deletion_eligibility_dto.dart';

@QueryHandlerFor(CheckProductDeletionEligibilityQuery)
final class CheckProductDeletionEligibilityQueryHandler
    implements IQueryHandler<CheckProductDeletionEligibilityQuery, ProductDeletionEligibilityDto> {
  CheckProductDeletionEligibilityQueryHandler({
    required IProductDeletionGateway deletionGateway,
    CheckProductDeletionEligibilityQueryValidator? validator,
  }) : _deletionGateway = deletionGateway,
       _validator = validator ?? CheckProductDeletionEligibilityQueryValidator();

  final IProductDeletionGateway _deletionGateway;
  final CheckProductDeletionEligibilityQueryValidator _validator;

  @override
  Future<ProductDeletionEligibilityDto> handle(
    CheckProductDeletionEligibilityQuery query,
  ) async {
    await _validator.validate(query);
    return _deletionGateway.checkDeletionEligibility(query);
  }
}
