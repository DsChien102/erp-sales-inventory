import 'package:uuid/uuid.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/pricing_blocked_codes.dart';
import '../../../shared/pricing_blocked_exception.dart';
import 'save_remembered_price_from_order_command.dart';

final class SaveRememberedPriceFromOrderCommandValidator
    implements ICommandValidator<SaveRememberedPriceFromOrderCommand> {
  static const _maxIdempotencyKeyLength = 200;

  @override
  Future<void> validate(SaveRememberedPriceFromOrderCommand command) async {
    final fieldErrors = <String, String>{};
    for (final entry in {
      'tenantId': command.tenantId,
      'actorId': command.actorId,
    }.entries) {
      if (entry.value.trim().isEmpty) {
        fieldErrors[entry.key] = 'required';
      }
    }
    for (final entry in {
      'sourceOrderId': command.sourceOrderId,
      'sourceOrderLineId': command.sourceOrderLineId,
      'productId': command.productId,
      'productUnitId': command.productUnitId,
    }.entries) {
      if (entry.value.trim().isEmpty) {
        fieldErrors[entry.key] = 'required';
      } else if (!Uuid.isValidUUID(fromString: entry.value)) {
        fieldErrors[entry.key] = 'invalid_uuid';
      }
    }
    final customerId = command.customerId?.trim();
    if (customerId != null &&
        customerId.isNotEmpty &&
        !Uuid.isValidUUID(fromString: customerId)) {
      fieldErrors['customerId'] = 'invalid_uuid';
    }
    if (command.soldPriceMinor <= 0) {
      fieldErrors['soldPriceMinor'] = 'must_be_positive';
    }
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(command.currencyCode)) {
      fieldErrors['currencyCode'] = 'invalid_currency';
    }
    if (command.idempotencyKey.isEmpty) {
      fieldErrors['idempotencyKey'] = 'required';
    } else if (command.idempotencyKey.length > _maxIdempotencyKeyLength) {
      fieldErrors['idempotencyKey'] = 'too_long';
    }
    if (!command.soldAt.isUtc) {
      fieldErrors['soldAt'] = 'must_be_utc';
    }
    if (fieldErrors.isNotEmpty) {
      throw PricingBlockedException(
        PricingBlockedCodes.validationError,
        message: 'Invalid remembered price payload.',
        details: {'fieldErrors': fieldErrors},
      );
    }
  }
}
