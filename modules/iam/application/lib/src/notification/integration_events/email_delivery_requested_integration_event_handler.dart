import 'package:vet45_iam_integration_events/integration_events.dart';

import '../../configurations/commands/i_command_scheduler.dart';
import '../commands/send_email_delivery/send_email_delivery_command.dart';
import '../shared/email_template_id.dart';

/// Inbox consumer: schedule [SendEmailDeliveryCommand] (does not call Resend).
final class EmailDeliveryRequestedIntegrationEventHandler
    implements
        IIntegrationEventNotificationHandler<
          EmailDeliveryRequestedIntegrationEvent
        > {
  EmailDeliveryRequestedIntegrationEventHandler({
    required ICommandScheduler commandScheduler,
  }) : _commandScheduler = commandScheduler;

  final ICommandScheduler _commandScheduler;

  @override
  Future<void> handle(EmailDeliveryRequestedIntegrationEvent event) async {
    await _commandScheduler.enqueue(
      SendEmailDeliveryCommand(
        tenantId: event.tenantId,
        templateId: EmailTemplateId.fromWire(event.templateId),
        toEmail: event.toEmail,
        correlationId: event.correlationId,
        outcomeId: event.outcomeId,
        locale: event.locale,
        refs: event.refs,
        secretPayloadCiphertext: event.secretPayloadCiphertext,
      ),
      sourceEventId: event.id,
    );
  }
}
