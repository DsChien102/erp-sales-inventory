import 'package:vet45_shared_application/application.dart';

import '../../../shared/sales_contract_exception.dart';
import 'cancel_return_exchange_command.dart';

final class CancelReturnExchangeCommandValidator
    implements ICommandValidator<CancelReturnExchangeCommand> {
  @override
  Future<void> validate(CancelReturnExchangeCommand command) async {
    _requireNotBlank(command.tenantId, 'tenantId');
    _requireNotBlank(command.actorId, 'actorId');
    _requireNotBlank(command.returnExchangeId, 'returnExchangeId');
    _requireNotBlank(command.idempotencyKey, 'idempotencyKey');
    final expectedVersion = command.expectedVersion;
    if (expectedVersion != null && expectedVersion < 1) {
      throw const SalesContractException(
        'CONTEXT_INVALID',
        message: 'expectedVersion must be positive when provided.',
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
