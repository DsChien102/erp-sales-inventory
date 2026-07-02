import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_integration_events/integration_events.dart';

import '../ports/i_partner_internal_command_dispatcher.dart';
import '../transaction_history/record_transaction_history/record_partner_transaction_history_command.dart';

/// Projects `accounting.payable.created` into partner transaction history (supplier role).
final class AccountingPayableCreatedIntegrationEventHandler
    implements
        IIntegrationEventNotificationHandler<AccountingPayableCreatedIntegrationEvent> {
  AccountingPayableCreatedIntegrationEventHandler({
    required IPartnerInternalCommandDispatcher internalCommandDispatcher,
  }) : _internalCommandDispatcher = internalCommandDispatcher;

  final IPartnerInternalCommandDispatcher _internalCommandDispatcher;

  @override
  Future<void> handle(AccountingPayableCreatedIntegrationEvent event) {
    return _internalCommandDispatcher.dispatch(
      RecordPartnerTransactionHistoryCommand(
        tenantId: event.tenantId,
        businessPartnerId: event.businessPartnerId,
        transactionRole: PartnerRole.supplier,
        sourceModule: 'accounting',
        sourceType: 'payable',
        sourceId: event.payableId,
        sourceCode: event.payableCode,
        transactionDate: event.transactionDate ?? event.occurredOn,
        amount: event.amount,
        status: event.status,
        description: event.description,
      ),
    );
  }
}
