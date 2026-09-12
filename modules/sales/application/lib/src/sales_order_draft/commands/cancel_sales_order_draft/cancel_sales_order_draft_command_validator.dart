import 'package:vet45_shared_application/application.dart';

import '../../../shared/sales_contract_exception.dart';
import 'cancel_sales_order_draft_command.dart';

final class CancelSalesOrderDraftCommandValidator
    implements ICommandValidator<CancelSalesOrderDraftCommand> {
  @override
  Future<void> validate(CancelSalesOrderDraftCommand command) async {
    _requireNotBlank(command.tenantId, 'tenantId');
    _requireNotBlank(command.actorId, 'actorId');
    _requireNotBlank(command.draftId, 'draftId');
    _requireNotBlank(command.idempotencyKey, 'idempotencyKey');
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
