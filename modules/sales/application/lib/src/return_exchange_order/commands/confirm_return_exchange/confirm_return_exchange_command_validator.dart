import 'package:vet45_shared_application/application.dart';

import '../../../shared/sales_contract_exception.dart';
import 'confirm_return_exchange_command.dart';

final class ConfirmReturnExchangeCommandValidator
    implements ICommandValidator<ConfirmReturnExchangeCommand> {
  @override
  Future<void> validate(ConfirmReturnExchangeCommand command) async {
    _requireNotBlank(command.tenantId, 'tenantId');
    _requireNotBlank(command.actorId, 'actorId');
    _requireNotBlank(command.returnExchangeId, 'returnExchangeId');
    _requireNotBlank(command.idempotencyKey, 'idempotencyKey');
    _requireNotBlank(command.payloadHash ?? '', 'payloadHash');
    _requireNotBlank(command.correlationId ?? '', 'correlationId');
    if (command.expectedVersion <= 0) {
      throw const SalesContractException(
        'CONTEXT_INVALID',
        message: 'expectedVersion must be positive.',
      );
    }
    final settledNow = command.settledNowMinor;
    if (settledNow != null && settledNow < 0) {
      throw const SalesContractException(
        'CONTEXT_INVALID',
        message: 'settledNowMinor cannot be negative.',
      );
    }
  }

  static void _requireNotBlank(String value, String field) {
    if (value.trim().isEmpty) {
      throw SalesContractException(
        'CONTEXT_INVALID',
        message: '$field is required.',
      );
    }
  }
}
