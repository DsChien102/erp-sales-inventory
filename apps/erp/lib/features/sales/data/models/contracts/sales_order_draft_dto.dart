import 'customer_snapshot_dto.dart';
import 'money_dto.dart';
import 'sales_contract_enums.dart';
import 'sales_order_draft_line_dto.dart';

final class SalesOrderDraftDto {
  SalesOrderDraftDto({
    required this.draftId,
    required this.version,
    required this.status,
    required this.storeId,
    required this.savedAt,
    required this.savedByActorId,
    required List<SalesOrderDraftLineDto> lines,
    required this.total,
    this.customer,
    this.orderNote,
    this.pricingPreviewToken,
    this.needsRevalidation = false,
  }) : lines = List.unmodifiable(lines);

  final String draftId;
  final int version;
  final SalesDraftStatus status;
  final String storeId;
  final CustomerSnapshotDto? customer;
  final String? orderNote;
  final DateTime savedAt;
  final String savedByActorId;
  final String? pricingPreviewToken;
  final bool needsRevalidation;
  final List<SalesOrderDraftLineDto> lines;
  final MoneyDto total;
}
