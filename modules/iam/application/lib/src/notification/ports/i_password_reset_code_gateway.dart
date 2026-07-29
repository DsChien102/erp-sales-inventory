/// Gateway: fetch plaintext password-reset code for email delivery.
///
/// Called by the worker's [SendEmailDeliveryCommandHandler] before rendering
/// the `password_reset_code` template. Returns null if the operation is
/// expired, completed, or not found — handler skips send and marks outcome failed.
///
/// Only service_role may invoke the backing RPC.
abstract interface class IPasswordResetCodeGateway {
  Future<String?> peekDeliveryCode(String operationId);
}
