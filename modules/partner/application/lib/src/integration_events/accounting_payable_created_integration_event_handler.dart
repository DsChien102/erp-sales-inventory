import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_integration_events/integration_events.dart';

import '../configurations/commands/i_command_scheduler.dart';
import '../transaction_history/record_transaction_history/record_partner_transaction_history_command.dart';

/// Projects `accounting.payable.created` into partner transaction history (supplier role).
final class AccountingPayableCreatedIntegrationEventHandler
    implements
        IIntegrationEventNotificationHandler<AccountingPayableCreatedIntegrationEvent> {
  AccountingPayableCreatedIntegrationEventHandler({
    required ICommandScheduler commandScheduler,
  }) : _commandScheduler = commandScheduler;

  final ICommandScheduler _commandScheduler;

  @override
  Future<void> handle(AccountingPayableCreatedIntegrationEvent event) {
    return _commandScheduler.enqueue(
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
      sourceEventId: event.id,
    );
  }
}
