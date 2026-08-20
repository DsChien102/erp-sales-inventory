import 'package:json_annotation/json_annotation.dart';

import 'email_delivery_constants.dart';

/// Maps nullable platform `tenant_id` in JSON ↔ messaging partition tenant id.
final class PlatformMessagingTenantIdConverter
    implements JsonConverter<String, Object?> {
  const PlatformMessagingTenantIdConverter();

  @override
  String fromJson(Object? json) {
    if (json == null || json == '') {
      return EmailDeliveryIntegrationEventConstants.platformMessagingTenantId;
    }
    return json as String;
  }

  @override
  Object? toJson(String object) {
    if (object ==
        EmailDeliveryIntegrationEventConstants.platformMessagingTenantId) {
      return null;
    }
    return object;
  }
}
