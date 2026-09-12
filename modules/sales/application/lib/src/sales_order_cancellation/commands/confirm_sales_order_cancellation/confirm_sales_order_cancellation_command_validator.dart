import 'package:vet45_shared_application/application.dart';

import '../../../shared/sales_contract_exception.dart';
import 'confirm_sales_order_cancellation_command.dart';

final class ConfirmSalesOrderCancellationCommandValidator
    implements ICommandValidator<ConfirmSalesOrderCancellationCommand> {
  @override
  Future<void> validate(ConfirmSalesOrderCancellationCommand command) async {
    _requireNotBlank(command.tenantId, 'tenantId');
    _requireNotBlank(command.actorId, 'actorId');
    _requireNotBlank(command.salesOrderId, 'salesOrderId');
    _requireNotBlank(command.idempotencyKey, 'idempotencyKey');
    _requireNotBlank(command.payloadHash ?? '', 'payloadHash');
    _requireNotBlank(command.correlationId ?? '', 'correlationId');
    if (command.expectedVersion <= 0) {
      throw const SalesContractException(
        'CONTEXT_INVALID',
        message: 'expectedVersion must be positive.',
      );
    }
    if (command.expectedSettlementVersion <= 0) {
      throw const SalesContractException(
        'CONTEXT_INVALID',
        message: 'expectedSettlementVersion must be positive.',
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
