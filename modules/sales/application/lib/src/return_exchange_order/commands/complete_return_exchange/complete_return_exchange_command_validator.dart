import 'package:vet45_shared_application/application.dart';

import '../../../shared/sales_contract_exception.dart';
import 'complete_return_exchange_command.dart';

final class CompleteReturnExchangeCommandValidator
    implements ICommandValidator<CompleteReturnExchangeCommand> {
  @override
  Future<void> validate(CompleteReturnExchangeCommand command) async {
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
