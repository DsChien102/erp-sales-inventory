import '../shared/email_template_id.dart';

/// Result of an outbound email send attempt (provider-agnostic).
final class EmailSendResult {
  const EmailSendResult({
    required this.isSuccess,
    this.messageId,
    this.error,
  });

  final bool isSuccess;
  final String? messageId;
  final String? error;
}

/// Sends a rendered email via the configured provider (e.g. Resend).
///
/// For both `password_reset_code` and `tenant_invitation`: the raw code/token
/// arrives only via [secretPayloadCiphertext] (transient encrypted channel
/// enqueued by the mutation RPC). It is never present in `refs`.
abstract interface class IEmailSenderGateway {
  Future<EmailSendResult> send({
    required EmailTemplateId templateId,
    required String toEmail,
    required String locale,
    required Map<String, String> refs,
    String? appLinkUrl,
    String? secretPayloadCiphertext,
  });
}
