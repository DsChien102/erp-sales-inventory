import 'partner_transaction_source_navigation_dto.dart';

final class PartnerTransactionHistoryItemDto {
  const PartnerTransactionHistoryItemDto({
    required this.id,
    required this.partnerId,
    required this.transactionRole,
    required this.transactionType,
    required this.occurredAt,
    required this.sourceNavigation,
    this.transactionCode,
    this.amount,
    this.status,
    this.description,
  });

  final String id;
  final String partnerId;
  final String transactionRole;
  final String transactionType;
  final DateTime occurredAt;
  final String? transactionCode;
  final double? amount;
  final String? status;
  final String? description;
  final PartnerTransactionSourceNavigationDto sourceNavigation;

  int? get amountMinor => amount?.round();
}
