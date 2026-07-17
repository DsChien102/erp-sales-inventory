import 'package:vet45_shared_application/application.dart';

import '../../../shared/pricing_blocked_codes.dart';
import '../../../shared/pricing_blocked_exception.dart';
import 'create_customer_price_rule_command.dart';

final class CreateCustomerPriceRuleCommandValidator
    implements ICommandValidator<CreateCustomerPriceRuleCommand> {
  @override
  Future<void> validate(CreateCustomerPriceRuleCommand command) async {
    final fieldErrors = <String, String>{};
    for (final entry in {
      'tenantId': command.tenantId,
      'actorId': command.actorId,
      'customerId': command.customerId,
      'productId': command.productId,
      'productUnitId': command.productUnitId,
      'idempotencyKey': command.idempotencyKey,
    }.entries) {
      if (entry.value.trim().isEmpty) {
        fieldErrors[entry.key] = 'required';
      }
    }
    if (command.rulePriceMinor <= 0) {
      fieldErrors['rulePriceMinor'] = 'must_be_positive';
    }
    if (!RegExp(
      r'^[A-Z]{3}$',
    ).hasMatch(command.currencyCode.trim().toUpperCase())) {
      fieldErrors['currencyCode'] = 'invalid_currency';
    }
    if (command.effectiveTo?.isBefore(command.effectiveFrom) ?? false) {
      fieldErrors['effectiveTo'] = 'before_effective_from';
    }
    if (fieldErrors.isNotEmpty) {
      throw PricingBlockedException(
        PricingBlockedCodes.validationError,
        message: 'Invalid customer price rule payload.',
        details: {'fieldErrors': fieldErrors},
      );
    }
  }
}
