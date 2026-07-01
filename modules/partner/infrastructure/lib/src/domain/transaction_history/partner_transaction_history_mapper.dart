import 'package:vet45_partner_application/application.dart';

abstract final class PartnerTransactionHistoryMapper {
  static PartnerTransactionHistoryItemDto fromRow(Map<String, dynamic> row) {
    final sourceModule = row['source_module'] as String;
    final sourceType = row['source_type'] as String;
    final sourceId = row['source_id'] as String;

    return PartnerTransactionHistoryItemDto(
      id: row['id'] as String,
      partnerId: row['business_partner_id'] as String,
      transactionRole: row['transaction_role'] as String,
      transactionType: sourceType,
      occurredAt: DateTime.parse(row['transaction_date'] as String),
      transactionCode: row['source_code'] as String?,
      amount: (row['amount'] as num?)?.toDouble(),
      status: row['status'] as String?,
      description: row['description'] as String?,
      sourceNavigation: PartnerTransactionSourceNavigationDto(
        sourceModule: sourceModule,
        sourceType: sourceType,
        sourceId: sourceId,
        requiredPermission: PartnerTransactionSourcePermissions.forSource(
          sourceModule: sourceModule,
          sourceType: sourceType,
        ),
      ),
    );
  }
}
