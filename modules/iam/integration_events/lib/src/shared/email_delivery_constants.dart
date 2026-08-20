/// Shared constants for IAM email-delivery integration events.
abstract final class EmailDeliveryIntegrationEventConstants {
  /// Outbox/inbox partition key for platform-scoped mail (not a domain tenant).
  static const platformMessagingTenantId =
      '00000000-0000-0000-0000-000000000000';
}
