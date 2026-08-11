/// Result of a Resend send attempt.
final class ResendSendResult {
  const ResendSendResult.ok(this.messageId)
    : error = null,
      rateLimited = false;

  const ResendSendResult.failed(this.error, {this.rateLimited = false})
    : messageId = null;

  final String? messageId;
  final String? error;
  final bool rateLimited;

  bool get isSuccess => messageId != null;
}

/// HTTP client for Resend email API (Notification adapter boundary).
abstract interface class IResendClient {
  Future<ResendSendResult> send({
    required String toEmail,
    required String subject,
    required String htmlBody,
    required String textBody,
  });
}
