import 'package:uuid/uuid.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/pricing_blocked_codes.dart';
import '../../../shared/pricing_blocked_exception.dart';
import 'resolve_applicable_customer_price_rule_query.dart';

final class ResolveApplicableCustomerPriceRuleQueryValidator
    implements ICommandValidator<ResolveApplicableCustomerPriceRuleQuery> {
  @override
  Future<void> validate(ResolveApplicableCustomerPriceRuleQuery query) async {
    final fieldErrors = <String, String>{};
    if (query.tenantId.trim().isEmpty) fieldErrors['tenantId'] = 'required';
    _requireUuid(fieldErrors, 'customerId', query.customerId);
    _requireUuid(fieldErrors, 'productId', query.productId);
    _requireUuid(fieldErrors, 'productUnitId', query.productUnitId);
    if (fieldErrors.isNotEmpty) {
      throw PricingBlockedException(
        PricingBlockedCodes.validationError,
        message: 'Invalid resolve applicable customer price rule payload.',
        details: {'fieldErrors': fieldErrors},
      );
    }
  }

  void _requireUuid(Map<String, String> fieldErrors, String field, String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      fieldErrors[field] = 'required';
    } else if (!Uuid.isValidUUID(fromString: value)) {
      fieldErrors[field] = 'invalid';
    }
  }
}
