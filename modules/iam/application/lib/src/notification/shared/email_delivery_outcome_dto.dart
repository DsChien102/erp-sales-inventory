import 'email_delivery_status.dart';
import 'email_template_id.dart';

/// Projection of a delivery attempt for UI (no raw tokens).
final class EmailDeliveryOutcomeDto {
  const EmailDeliveryOutcomeDto({
    required this.id,
    required this.templateId,
    required this.status,
    required this.correlationId,
    required this.provider,
    this.tenantId,
    this.providerMessageId,
    this.error,
    this.toEmailMasked,
  });

  final String id;
  final String? tenantId;
  final EmailTemplateId templateId;
  final EmailDeliveryStatus status;
  final String correlationId;
  final String provider;
  final String? providerMessageId;
  final String? error;
  final String? toEmailMasked;
}
