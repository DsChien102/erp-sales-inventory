import '../shared/email_delivery_outcome_dto.dart';
import '../shared/email_delivery_status.dart';
import '../shared/email_template_id.dart';
import '../shared/enqueue_email_delivery_request.dart';

/// Projection store for email delivery outcomes (queued → sent/failed).
abstract interface class IEmailDeliveryOutcomeStore {
  Future<String> record({
    required String correlationId,
    required EmailTemplateId templateId,
    required EmailDeliveryStatus status,
    String? tenantId,
    String? toEmailMasked,
    String? providerMessageId,
    String? error,
    String provider = EmailDeliveryConstants.providerResend,
    String? id,
  });

  Future<EmailDeliveryOutcomeDto?> getByCorrelationId(String correlationId);

  Future<bool> isCurrentTenantInvitationDelivery({
    required String invitationId,
    required String correlationId,
  });
}
