import 'package:erp/features/sales/data/models/sales_draft_list_page.dart';
import 'package:erp/features/sales/data/models.dart';

/// Dựng tham số RPC + đọc JSON của 5 RPC nháp (chép từ SalesOrderDraftRpcMapper).
/// Trả DTO của `data/models.dart` (Q1); 8-C chép kiểu.
abstract final class SalesDraftJson {
  static Map<String, dynamic>? customerParams(CustomerSnapshotDto? customer) {
    if (customer == null) return null;
    return <String, dynamic>{
      'customer_id': customer.customerId,
      'display_name': customer.displayName,
      if (customer.phoneNumber != null) 'phone_number': customer.phoneNumber,
      if (customer.taxCode != null) 'tax_code': customer.taxCode,
      if (customer.buyerType != null) 'buyer_type': customer.buyerType,
      if (customer.invoiceLegalName != null) 'invoice_legal_name': customer.invoiceLegalName,
      if (customer.invoiceAddress != null) 'invoice_address': customer.invoiceAddress,
      if (customer.invoiceEmail != null) 'invoice_email': customer.invoiceEmail,
    };
  }

  static List<Map<String, dynamic>> lineParams(List<SalesOrderDraftLineInput> lines) {
    return [
      for (final line in lines)
        <String, dynamic>{
          'product_id': line.productId,
          'product_sku': line.productSku,
          'product_name': line.productName,
          'product_unit_id': line.productUnitId,
          'unit_code': line.unitCode,
          'unit_name': line.unitName,
          'quantity_micros': line.quantity.quantityMicros,
          'applied_unit_price_minor': line.appliedUnitPrice.amountMinor,
          'line_total_minor': line.lineTotal.amountMinor,
          if (line.listUnitPrice != null) 'list_unit_price_minor': line.listUnitPrice!.amountMinor,
          if (line.manualUnitPriceMinor != null)
            'manual_unit_price_minor': line.manualUnitPriceMinor,
          if (line.manualDiscountMinor != null) 'manual_discount_minor': line.manualDiscountMinor,
          if (line.manualDiscountBasisPoints != null)
            'manual_discount_basis_points': line.manualDiscountBasisPoints,
          if (line.pricingSourceCode != null) 'pricing_source_code': line.pricingSourceCode,
          'pricing_warning_codes': line.pricingWarningCodes,
          'pricing_blocking_codes': line.pricingBlockingCodes,
          'note': line.note,
          'needs_revalidation': line.needsRevalidation,
        },
    ];
  }

  static SalesOrderDraftDto draft(Map<String, dynamic> json) {
    return SalesOrderDraftContractMapper.toDraftDto(_row(json));
  }

  static SalesOrderDraftForRestoreDto restore(Map<String, dynamic> json) {
    final draftJson = _map(json['draft']);
    return SalesOrderDraftForRestoreDto(
      draft: draft(draftJson),
      savedAt: _dateTime(json['saved_at']),
      savedByActorId: _string(json, 'saved_by_actor_id'),
    );
  }

  static SalesDraftListPage page(Map<String, dynamic> json) {
    final items = json['items'];
    final hasMore = json['has_more'];
    if (hasMore is! bool) {
      throw const FormatException('Expected required boolean field has_more.');
    }
    final totalCount = json['total_count'];
    if (totalCount is! int) {
      throw const FormatException('Expected required integer field total_count.');
    }
    final list = <SalesDraftListEntry>[];
    if (items is List) {
      for (final item in items) {
        if (item is Map) {
          final m = item.cast<String, dynamic>();
          list.add(
            SalesDraftListEntry(
              draft: draft(m),
              createdByUserId: (m['created_by_user_id'] as String?)?.trim() ?? '',
              createdByName: (m['created_by_name'] as String?)?.trim(),
            ),
          );
        }
      }
    }
    return SalesDraftListPage(
      items: List.unmodifiable(list),
      hasMore: hasMore,
      totalCount: totalCount,
      nextCursor: json['next_cursor'] as String?,
    );
  }

  static SalesOrderDraftReadRow _row(Map<String, dynamic> json) {
    final lines = json['lines'];
    return SalesOrderDraftReadRow(
      draftId: _string(json, 'draft_id'),
      version: _int(json['version']),
      status: _status(_string(json, 'status')),
      storeId: _string(json, 'store_id'),
      currencyCode: _string(json, 'currency_code'),
      savedAt: _dateTime(json['saved_at']),
      savedByActorId: _string(json, 'saved_by_actor_id'),
      customer: _customer(json['customer']),
      orderNote: json['order_note'] as String?,
      pricingPreviewToken: json['pricing_preview_token'] as String?,
      needsRevalidation: _bool(json['needs_revalidation']),
      lines: lines is List
          ? lines
                .whereType<Map>()
                .map((item) => _line(item.cast<String, dynamic>(), json))
                .toList(growable: false)
          : const [],
    );
  }

  static SalesOrderDraftLineReadRow _line(
    Map<String, dynamic> json,
    Map<String, dynamic> draft,
  ) {
    final currency = _string(draft, 'currency_code');
    return SalesOrderDraftLineReadRow(
      lineId: _string(json, 'line_id'),
      productId: _string(json, 'product_id'),
      productSku: _string(json, 'product_sku'),
      productName: _string(json, 'product_name'),
      productUnitId: _string(json, 'product_unit_id'),
      unitCode: _string(json, 'unit_code'),
      unitName: _string(json, 'unit_name'),
      quantity: QuantityDto(quantityMicros: _int(json['quantity_micros'])),
      appliedUnitPrice: MoneyDto(
        amountMinor: _int(json['applied_unit_price_minor']),
        currencyCode: currency,
      ),
      lineTotal: MoneyDto(
        amountMinor: _int(json['line_total_minor']),
        currencyCode: currency,
      ),
      listUnitPrice: json['list_unit_price_minor'] == null
          ? null
          : MoneyDto(
              amountMinor: _int(json['list_unit_price_minor']),
              currencyCode: currency,
            ),
      manualUnitPriceMinor: _optionalInt(json['manual_unit_price_minor']),
      manualDiscountMinor: _optionalInt(json['manual_discount_minor']),
      manualDiscountBasisPoints: _optionalInt(json['manual_discount_basis_points']),
      pricingSourceCode: json['pricing_source_code'] as String?,
      pricingWarningCodes: _stringList(json['pricing_warning_codes']),
      pricingBlockingCodes: _stringList(json['pricing_blocking_codes']),
      note: json['note'] as String?,
      needsRevalidation: _bool(json['needs_revalidation']),
    );
  }

  static CustomerSnapshotDto? _customer(Object? value) {
    if (value == null) return null;
    final json = _map(value);
    return CustomerSnapshotDto(
      customerId: _string(json, 'customer_id'),
      displayName: _string(json, 'display_name'),
      phoneNumber: json['phone_number'] as String?,
      taxCode: json['tax_code'] as String?,
      existingDebtMinor: 0,
      buyerType: json['buyer_type'] as String?,
      invoiceLegalName: json['invoice_legal_name'] as String?,
      invoiceAddress: json['invoice_address'] as String?,
      invoiceEmail: json['invoice_email'] as String?,
    );
  }

  static Map<String, dynamic> _map(Object? value) {
    if (value is Map) return value.cast<String, dynamic>();
    throw FormatException('Expected JSON object, got $value.');
  }

  static String _string(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) return value;
    throw FormatException('Expected required string field $key.');
  }

  static int _int(Object? value) {
    if (value is int) return value;
    if (value is num && value.isFinite && value == value.truncateToDouble()) {
      return value.toInt();
    }
    throw FormatException('Expected integer value, got $value.');
  }

  static int? _optionalInt(Object? value) {
    if (value == null) return null;
    return _int(value);
  }

  static bool _bool(Object? value) {
    if (value is bool) return value;
    throw FormatException('Expected boolean value, got $value.');
  }

  static List<String> _stringList(Object? value) {
    if (value == null) return const [];
    if (value is! List) {
      throw FormatException('Expected string list, got $value.');
    }
    return [
      for (final item in value)
        if (item is String)
          item
        else
          throw FormatException('Expected string list item, got $item.'),
    ];
  }

  static DateTime _dateTime(Object? value) {
    if (value is DateTime) return value.toUtc();
    if (value is String) return DateTime.parse(value).toUtc();
    throw FormatException('Expected ISO timestamp, got $value.');
  }

  static SalesDraftStatus _status(String value) {
    return switch (value) {
      'active' => SalesDraftStatus.active,
      'converted' => SalesDraftStatus.converted,
      'cancelled' => SalesDraftStatus.cancelled,
      'expired' => SalesDraftStatus.expired,
      _ => throw FormatException('Unknown draft status $value.'),
    };
  }
}
