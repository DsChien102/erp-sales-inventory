import 'package:vet45_shared_application/application.dart';

import '../../../shared/return_exchange_line_input.dart';
import '../../../shared/sales_contract_enums.dart';
import '../../../shared/sales_contract_exception.dart';
import 'update_return_exchange_command.dart';

final class UpdateReturnExchangeCommandValidator
    implements ICommandValidator<UpdateReturnExchangeCommand> {
  @override
  Future<void> validate(UpdateReturnExchangeCommand command) async {
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
    _validateLines(command.lines);
  }

  static void _validateLines(List<ReturnExchangeLineInput> lines) {
    for (final line in lines) {
      if (line.quantity.quantityMicros <= 0) {
        throw const SalesContractException(
          'CONTEXT_INVALID',
          message: 'line quantity must be positive.',
        );
      }
      switch (line.kind) {
        case ReturnExchangeLineKind.returnLine:
          final hasOriginal =
              line.originalSalesOrderLineId?.trim().isNotEmpty ?? false;
          final hasExchange =
              line.sourceExchangeLineId?.trim().isNotEmpty ?? false;
          if (hasOriginal == hasExchange) {
            throw const SalesContractException(
              'CONTEXT_INVALID',
              message:
                  'return lines require exactly one source: original or exchange.',
            );
          }
        case ReturnExchangeLineKind.exchangeLine:
          if (line.originalSalesOrderLineId != null ||
              line.sourceExchangeLineId != null) {
            throw const SalesContractException(
              'CONTEXT_INVALID',
              message: 'exchange lines must not reference a return source.',
            );
          }
          if (line.reasonCode != null || line.conditionCode != null) {
            throw const SalesContractException(
              'CONTEXT_INVALID',
              message: 'exchange lines must not carry reason or condition.',
            );
          }
      }
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
