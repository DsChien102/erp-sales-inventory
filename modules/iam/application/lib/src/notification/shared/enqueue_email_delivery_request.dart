import 'email_template_id.dart';

/// Request DTO describing an email delivery (used by Fake / contracts).
///
/// Production: mutation RPC persists business row + `enqueue_outbox_message`
/// (and optional queued outcome) in one transaction — not Dart outbox client.
///
/// Must not include raw invitation/activation tokens or password-reset codes.
/// If raw secret delivery is required, use encrypted transient
/// `secret_payload_ciphertext` (key outside DB) — never put secrets in [refs].
final class EnqueueEmailDeliveryRequest {
  const EnqueueEmailDeliveryRequest({
    required this.templateId,
    required this.toEmail,
    required this.correlationId,
    required this.tenantId,
    this.locale = 'vi',
    this.refs = const <String, String>{},
    this.secretPayloadCiphertext,
  });

  final EmailTemplateId templateId;
  final String toEmail;
  final String correlationId;

  /// Outbox / internal commands require tenant scope. Use
  /// [EmailDeliveryConstants.platformTenantId] for platform-scoped mail
  /// (activation / password reset) when no tenant applies. Payload still
  /// serializes `tenant_id: null` for platform scope.
  final String tenantId;

  final String locale;

  /// Opaque refs only (e.g. invitation_id, operation_id) — never raw secrets.
  final Map<String, String> refs;

  /// Encrypted transient secret channel (optional).
  final String? secretPayloadCiphertext;
}

/// Sentinel tenant for platform-scoped email messaging rows.
abstract final class EmailDeliveryConstants {
  static const platformTenantId = '00000000-0000-0000-0000-000000000000';

  /// Outbox `event_type` written by mutation RPC via `enqueue_outbox_message`.
  static const outboxEventType = 'iam.email.delivery_requested';
  static const providerResend = 'resend';
}
