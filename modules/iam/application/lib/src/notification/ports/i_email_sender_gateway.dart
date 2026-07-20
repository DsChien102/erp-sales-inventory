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
abstract interface class IEmailSenderGateway {
  Future<EmailSendResult> send({
    required EmailTemplateId templateId,
    required String toEmail,
    required String locale,
    required Map<String, String> refs,
    String? appLinkUrl,
  });
}
