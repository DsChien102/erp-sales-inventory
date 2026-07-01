import 'package:vet45_shared_infrastructure/infrastructure.dart';

/// Shared payload fields for partner transaction-history projection ingest.
abstract final class PartnerTransactionHistoryEventPayload {
  static String requireTenantId(Map<String, dynamic> json) {
    final tenantId = json['tenant_id'] as String?;
    if (tenantId == null || tenantId.isEmpty) {
      throw FormatException('transaction history event requires tenant_id');
    }
    return tenantId;
  }

  static String requireBusinessPartnerId(Map<String, dynamic> json) {
    final partnerId =
        json['business_partner_id'] as String? ?? json['partner_id'] as String?;
    if (partnerId == null || partnerId.isEmpty) {
      throw FormatException(
        'transaction history event requires business_partner_id',
      );
    }
    return partnerId;
  }

  static String requireSourceId(Map<String, dynamic> json) {
    final sourceId = json['source_id'] as String? ?? json['id'] as String?;
    if (sourceId == null || sourceId.isEmpty) {
      throw FormatException('transaction history event requires source_id');
    }
    return sourceId;
  }

  static DateTime resolveTransactionDate(Map<String, dynamic> json) {
    final raw =
        json['transaction_date'] as String? ?? json['occurred_on'] as String?;
    if (raw == null || raw.isEmpty) {
      return integrationEventOccurredOnFromMap(json);
    }
    return DateTime.parse(raw).toUtc();
  }
}
