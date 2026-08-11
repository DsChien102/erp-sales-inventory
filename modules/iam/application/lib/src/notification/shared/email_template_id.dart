/// Logical email templates for Theme 1 Notification (Resend).
enum EmailTemplateId {
  activationInvitation('activation_invitation'),
  tenantInvitation('tenant_invitation'),
  passwordResetCode('password_reset_code'),
  securityNotification('security_notification');

  const EmailTemplateId(this.wireValue);

  final String wireValue;

  static EmailTemplateId fromWire(String value) {
    for (final id in EmailTemplateId.values) {
      if (id.wireValue == value) {
        return id;
      }
    }
    throw ArgumentError.value(value, 'value', 'Unknown email template id');
  }
}
