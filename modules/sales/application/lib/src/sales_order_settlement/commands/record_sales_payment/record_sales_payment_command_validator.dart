import 'package:vet45_shared_application/application.dart';

import '../../../shared/sales_contract_exception.dart';
import 'record_sales_payment_command.dart';

final class RecordSalesPaymentCommandValidator
    implements ICommandValidator<RecordSalesPaymentCommand> {
  @override
  Future<void> validate(RecordSalesPaymentCommand command) async {
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
    _validateMoney(command);
  }

  static void _validateMoney(RecordSalesPaymentCommand command) {
    if (command.amount.amountMinor <= 0) {
      throw const SalesContractException(
        'CONTEXT_INVALID',
        message: 'amount must be positive.',
      );
    }
    _requireNotBlank(command.amount.currencyCode, 'currencyCode');
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
