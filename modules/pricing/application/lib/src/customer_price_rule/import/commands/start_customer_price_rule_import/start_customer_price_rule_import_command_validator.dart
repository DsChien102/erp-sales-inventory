import 'package:vet45_shared_application/application.dart';

import '../../../../shared/pricing_blocked_codes.dart';
import '../../../../shared/pricing_blocked_exception.dart';
import 'start_customer_price_rule_import_command.dart';

final class StartCustomerPriceRuleImportCommandValidator
    implements ICommandValidator<StartCustomerPriceRuleImportCommand> {
  static const _maxFileSizeBytes = 5 * 1024 * 1024;

  @override
  Future<void> validate(StartCustomerPriceRuleImportCommand command) async {
    final fieldErrors = <String, String>{};
    for (final entry in {
      'tenantId': command.tenantId,
      'actorId': command.actorId,
      'templateVersion': command.templateVersion,
      'originalFileName': command.originalFileName,
    }.entries) {
      if (entry.value.trim().isEmpty) {
        fieldErrors[entry.key] = 'required';
      }
    }
    if (!command.originalFileName.toLowerCase().trim().endsWith('.xlsx')) {
      fieldErrors['originalFileName'] = 'invalid_extension';
    }
    if (command.fileBytes.isEmpty) {
      fieldErrors['fileBytes'] = 'required';
    }
    if (command.fileBytes.length > _maxFileSizeBytes) {
      fieldErrors['fileBytes'] = 'file_too_large';
    }
    if (fieldErrors.isNotEmpty) {
      throw PricingBlockedException(
        PricingBlockedCodes.validationError,
        message: 'Invalid import start payload.',
        details: {'fieldErrors': fieldErrors},
      );
    }
  }
}
