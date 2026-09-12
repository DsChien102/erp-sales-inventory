import 'package:vet45_shared_application/application.dart';

import '../../../shared/sales_contract_exception.dart';
import 'finalize_sales_order_command.dart';

final class FinalizeSalesOrderCommandValidator
    implements ICommandValidator<FinalizeSalesOrderCommand> {
  @override
  Future<void> validate(FinalizeSalesOrderCommand command) async {
    _requireNotBlank(command.tenantId, 'tenantId');
    _requireNotBlank(command.actorId, 'actorId');
    _requireNotBlank(command.storeId, 'storeId');
    _requireNotBlank(command.currencyCode, 'currencyCode');
    _requireNotBlank(command.idempotencyKey, 'idempotencyKey');
    _requireNotBlank(command.payloadHash ?? '', 'payloadHash');
    _requireNotBlank(command.correlationId ?? '', 'correlationId');
    if (command.lines.isEmpty) {
      throw const SalesContractException(
        'CONTEXT_INVALID',
        message: 'Finalize checkout requires at least one line.',
      );
    }
    for (final line in command.lines) {
      _requireNotBlank(line.productId, 'productId');
      _requireNotBlank(line.productUnitId, 'productUnitId');
      if (line.quantity.quantityMicros <= 0) {
        throw const SalesContractException(
          'CONTEXT_INVALID',
          message: 'Checkout line quantity must be positive.',
        );
      }
    }
    for (final intent in command.paymentIntents) {
      if (intent.amount.amountMinor <= 0) {
        throw const SalesContractException(
          'CONTEXT_INVALID',
          message: 'Payment intent amount must be greater than zero.',
        );
      }
      _requireNotBlank(intent.amount.currencyCode, 'paymentCurrencyCode');
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
