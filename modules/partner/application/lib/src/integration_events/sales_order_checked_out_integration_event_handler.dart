import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_partner_integration_events/integration_events.dart';

import '../ports/i_partner_internal_command_dispatcher.dart';
import '../transaction_history/record_transaction_history/record_partner_transaction_history_command.dart';

/// Projects `sales.order.checked_out` into partner transaction history (customer role).
final class SalesOrderCheckedOutIntegrationEventHandler
    implements
        IIntegrationEventNotificationHandler<SalesOrderCheckedOutIntegrationEvent> {
  SalesOrderCheckedOutIntegrationEventHandler({
    required IPartnerInternalCommandDispatcher internalCommandDispatcher,
  }) : _internalCommandDispatcher = internalCommandDispatcher;

  final IPartnerInternalCommandDispatcher _internalCommandDispatcher;

  @override
  Future<void> handle(SalesOrderCheckedOutIntegrationEvent event) {
    return _internalCommandDispatcher.dispatch(
      RecordPartnerTransactionHistoryCommand(
        tenantId: event.tenantId,
        businessPartnerId: event.businessPartnerId,
        transactionRole: PartnerRole.customer,
        sourceModule: 'sales',
        sourceType: 'order',
        sourceId: event.orderId,
        sourceCode: event.orderCode,
        transactionDate: event.transactionDate ?? event.occurredOn,
        amount: event.amount,
        status: event.status,
        description: event.description,
      ),
    );
  }
}
