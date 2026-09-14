import '../../shared/customer_snapshot_dto.dart';
import '../../shared/money_dto.dart';
import '../../shared/opaque_cursor_page_dto.dart';
import '../../shared/paged_sales_order_draft_list_dto.dart';
import '../../shared/quantity_dto.dart';
import '../../shared/sales_contract_enums.dart';
import '../../shared/sales_order_draft_dto.dart';
import '../../shared/sales_order_draft_for_restore_dto.dart';
import '../../shared/sales_order_draft_line_dto.dart';

const _walkInCustomerId = 'cust-walk-in';

final class SalesOrderDraftLineReadRow {
  SalesOrderDraftLineReadRow({
    required this.lineId,
    required this.productId,
    required this.productSku,
    required this.productName,
    required this.productUnitId,
    required this.unitCode,
    required this.unitName,
    required this.quantity,
    required this.appliedUnitPrice,
    required this.lineTotal,
    this.listUnitPrice,
    this.manualUnitPriceMinor,
    this.manualDiscountMinor,
    this.manualDiscountBasisPoints,
    this.pricingSourceCode,
    List<String> pricingWarningCodes = const [],
    List<String> pricingBlockingCodes = const [],
    this.note,
    this.needsRevalidation = false,
  }) : pricingWarningCodes = List.unmodifiable(pricingWarningCodes),
       pricingBlockingCodes = List.unmodifiable(pricingBlockingCodes);

  final String lineId;
  final String productId;
  final String productSku;
  final String productName;
  final String productUnitId;
  final String unitCode;
  final String unitName;
  final QuantityDto quantity;
  final MoneyDto appliedUnitPrice;
  final MoneyDto lineTotal;
  final MoneyDto? listUnitPrice;
  final int? manualUnitPriceMinor;
  final int? manualDiscountMinor;
  final int? manualDiscountBasisPoints;
  final String? pricingSourceCode;
  final List<String> pricingWarningCodes;
  final List<String> pricingBlockingCodes;
  final String? note;
  final bool needsRevalidation;
}

final class SalesOrderDraftReadRow {
  SalesOrderDraftReadRow({
    required this.draftId,
    required this.version,
    required this.status,
    required this.storeId,
    required this.currencyCode,
    required this.savedAt,
    required this.savedByActorId,
    required List<SalesOrderDraftLineReadRow> lines,
    this.customer,
    this.orderNote,
    this.pricingPreviewToken,
    this.needsRevalidation = false,
  }) : lines = List.unmodifiable(lines);

  final String draftId;
  final int version;
  final SalesDraftStatus status;
  final String storeId;
  final String currencyCode;
  final DateTime savedAt;
  final String savedByActorId;
  final CustomerSnapshotDto? customer;
  final String? orderNote;
  final String? pricingPreviewToken;
  final bool needsRevalidation;
  final List<SalesOrderDraftLineReadRow> lines;
}

abstract final class SalesOrderDraftContractMapper {
  static SalesOrderDraftDto toDraftDto(SalesOrderDraftReadRow row) {
    final lines = row.lines.map(_lineDto).toList(growable: false);
    final total = lines.fold<int>(
      0,
      (sum, line) => sum + line.lineTotal.amountMinor,
    );
    return SalesOrderDraftDto(
      draftId: row.draftId,
      version: row.version,
      status: row.status,
      storeId: row.storeId,
      customer: _mapCustomer(row.customer),
      orderNote: _normalizeOptionalText(row.orderNote),
      savedAt: row.savedAt,
      savedByActorId: row.savedByActorId,
      pricingPreviewToken: row.pricingPreviewToken,
      needsRevalidation: row.needsRevalidation,
      lines: lines,
      total: MoneyDto(amountMinor: total, currencyCode: row.currencyCode),
    );
  }

  static SalesOrderDraftForRestoreDto toRestoreDto(SalesOrderDraftReadRow row) {
    final draft = toDraftDto(row);
    return SalesOrderDraftForRestoreDto(
      draft: draft,
      savedAt: draft.savedAt,
      savedByActorId: draft.savedByActorId,
    );
  }

  static PagedSalesOrderDraftListDto toPageDto({
    required List<SalesOrderDraftReadRow> rows,
    required bool hasMore,
    String? nextCursor,
  }) {
    return PagedSalesOrderDraftListDto(
      page: OpaqueCursorPageDto<SalesOrderDraftDto>(
        items: rows.map(toDraftDto).toList(growable: false),
        hasMore: hasMore,
        nextCursor: nextCursor,
      ),
    );
  }

  static CustomerSnapshotDto? _mapCustomer(CustomerSnapshotDto? customer) {
    if (customer == null) return null;
    if (customer.customerId.trim() == _walkInCustomerId) return null;
    return CustomerSnapshotDto(
      customerId: customer.customerId,
      displayName: customer.displayName,
      phoneNumber: customer.phoneNumber,
      taxCode: customer.taxCode,
      existingDebtMinor: 0,
    );
  }

  static String? _normalizeOptionalText(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static SalesOrderDraftLineDto _lineDto(SalesOrderDraftLineReadRow row) {
    return SalesOrderDraftLineDto(
      lineId: row.lineId,
      productId: row.productId,
      productSku: row.productSku,
      productName: row.productName,
      productUnitId: row.productUnitId,
      unitCode: row.unitCode,
      unitName: row.unitName,
      quantity: row.quantity,
      appliedUnitPrice: row.appliedUnitPrice,
      lineTotal: row.lineTotal,
      listUnitPrice: row.listUnitPrice,
      manualUnitPriceMinor: row.manualUnitPriceMinor,
      manualDiscountMinor: row.manualDiscountMinor,
      manualDiscountBasisPoints: row.manualDiscountBasisPoints,
      pricingSourceCode: row.pricingSourceCode,
      pricingWarningCodes: row.pricingWarningCodes,
      pricingBlockingCodes: row.pricingBlockingCodes,
      note: row.note,
      needsRevalidation: row.needsRevalidation,
    );
  }
}
