import 'package:vet45_shared_application/application.dart';

import '../../ports/i_email_delivery_outcome_store.dart';
import '../../ports/i_email_sender_gateway.dart';
import '../../shared/email_delivery_status.dart';
import '../../shared/email_template_id.dart';
import '../../shared/enqueue_email_delivery_request.dart';
import 'send_email_delivery_command.dart';

@CommandHandlerFor(SendEmailDeliveryCommand)
final class SendEmailDeliveryCommandHandler
    implements ICommandHandler<SendEmailDeliveryCommand, void> {
  SendEmailDeliveryCommandHandler({
    required IEmailSenderGateway emailSender,
    required IEmailDeliveryOutcomeStore outcomes,
  }) : _emailSender = emailSender,
       _outcomes = outcomes;

  final IEmailSenderGateway _emailSender;
  final IEmailDeliveryOutcomeStore _outcomes;

  @override
  Future<void> handle(SendEmailDeliveryCommand command) async {
    if (!await _isFresh(command)) {
      await _outcomes.record(
        id: command.outcomeId,
        correlationId: command.correlationId,
        templateId: command.templateId,
        status: EmailDeliveryStatus.failed,
        tenantId: command.tenantId == EmailDeliveryConstants.platformTenantId
            ? null
            : command.tenantId,
        toEmailMasked: maskEmail(command.toEmail),
        error: 'stale_invitation_delivery',
      );
      return;
    }

    final result = await _emailSender.send(
      templateId: command.templateId,
      toEmail: command.toEmail,
      locale: command.locale,
      refs: command.refs,
      secretPayloadCiphertext: command.secretPayloadCiphertext,
    );

    final status = result.isSuccess ? EmailDeliveryStatus.sent : EmailDeliveryStatus.failed;

    await _outcomes.record(
      id: command.outcomeId,
      correlationId: command.correlationId,
      templateId: command.templateId,
      status: status,
      tenantId: command.tenantId == EmailDeliveryConstants.platformTenantId
          ? null
          : command.tenantId,
      toEmailMasked: maskEmail(command.toEmail),
      providerMessageId: result.messageId,
      error: result.error,
    );

    if (!result.isSuccess) {
      throw StateError(result.error ?? 'email_delivery_failed');
    }
  }

  Future<bool> _isFresh(SendEmailDeliveryCommand command) async {
    if (command.templateId != EmailTemplateId.tenantInvitation) {
      return true;
    }
    final invitationId = command.refs['invitation_id'];
    if (invitationId == null || invitationId.trim().isEmpty) {
      return true;
    }
    return _outcomes.isCurrentTenantInvitationDelivery(
      invitationId: invitationId,
      correlationId: command.correlationId,
    );
  }

  static String maskEmail(String email) {
    final at = email.indexOf('@');
    if (at <= 1) {
      return '***';
    }
    return '${email[0]}***${email.substring(at)}';
  }
}
