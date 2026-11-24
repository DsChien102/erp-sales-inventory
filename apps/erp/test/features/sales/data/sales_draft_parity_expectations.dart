import 'package:erp/features/sales/data/models/sales_draft_list_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/sales/data/models.dart';

const draftParityTenantId = 'tenant-1';
const draftParityActorId = 'user-1';
const draftParityStoreId = 'store-1';

/// Mapper cũ KHÔNG trim draftId ⇒ giữ khoảng trắng.
const draftParityDraftId = '  draft-1  ';
const draftParityCurrencyRaw = ' vnd ';
const draftParityIdempotencyRaw = ' k1 ';

CustomerSnapshotDto draftParityCustomer() => const CustomerSnapshotDto(
  customerId: 'customer-1',
  displayName: 'Nguyen Van A',
  phoneNumber: '0901234567',
  taxCode: '0312345678',
);

List<SalesOrderDraftLineInput> draftParityLines() => [
  SalesOrderDraftLineInput(
    productId: 'product-1',
    productSku: 'SKU-1',
    productName: 'Thuoc A',
    productUnitId: 'unit-1',
    unitCode: 'BOX',
    unitName: 'Hop',
    quantity: const QuantityDto(quantityMicros: QuantityDto.scale),
    appliedUnitPrice: const MoneyDto(amountMinor: 120000, currencyCode: 'VND'),
    lineTotal: const MoneyDto(amountMinor: 115000, currencyCode: 'VND'),
    listUnitPrice: const MoneyDto(amountMinor: 130000, currencyCode: 'VND'),
    manualDiscountMinor: 5000,
    pricingSourceCode: 'list',
    pricingWarningCodes: const ['PRICE_STALE'],
    note: 'Line note',
  ),
  SalesOrderDraftLineInput(
    productId: 'product-2',
    productSku: 'SKU-2',
    productName: 'Thuoc B',
    productUnitId: 'unit-2',
    unitCode: 'PCS',
    unitName: 'Vien',
    quantity: const QuantityDto(quantityMicros: 2 * QuantityDto.scale),
    appliedUnitPrice: const MoneyDto(amountMinor: 10000, currencyCode: 'VND'),
    lineTotal: const MoneyDto(amountMinor: 20000, currencyCode: 'VND'),
  ),
];

const _expectedCustomerParams = <String, dynamic>{
  'customer_id': 'customer-1',
  'display_name': 'Nguyen Van A',
  'phone_number': '0901234567',
  'tax_code': '0312345678',
};

const _expectedLineParams = <Map<String, dynamic>>[
  {
    'product_id': 'product-1',
    'product_sku': 'SKU-1',
    'product_name': 'Thuoc A',
    'product_unit_id': 'unit-1',
    'unit_code': 'BOX',
    'unit_name': 'Hop',
    'quantity_micros': QuantityDto.scale,
    'applied_unit_price_minor': 120000,
    'line_total_minor': 115000,
    'list_unit_price_minor': 130000,
    'manual_discount_minor': 5000,
    'pricing_source_code': 'list',
    'pricing_warning_codes': ['PRICE_STALE'],
    'pricing_blocking_codes': <String>[],
    'note': 'Line note',
    'needs_revalidation': false,
  },
  {
    'product_id': 'product-2',
    'product_sku': 'SKU-2',
    'product_name': 'Thuoc B',
    'product_unit_id': 'unit-2',
    'unit_code': 'PCS',
    'unit_name': 'Vien',
    'quantity_micros': 2 * QuantityDto.scale,
    'applied_unit_price_minor': 10000,
    'line_total_minor': 20000,
    'pricing_warning_codes': <String>[],
    'pricing_blocking_codes': <String>[],
    'note': null,
    'needs_revalidation': false,
  },
];

const expectedSaveParams = <String, dynamic>{
  'p_tenant_id': draftParityTenantId,
  'p_actor_id': draftParityActorId,
  'p_store_id': draftParityStoreId,
  'p_customer': _expectedCustomerParams,
  'p_currency_code': 'VND',
  'p_order_note': 'Giao buoi chieu',
  'p_pricing_preview_token': 'preview-token-1',
  'p_needs_revalidation': true,
  'p_lines': _expectedLineParams,
  'p_idempotency_key': 'k1',
  'p_payload_hash': 'hash-1',
};

const expectedUpdateParams = <String, dynamic>{
  'p_tenant_id': draftParityTenantId,
  'p_actor_id': draftParityActorId,
  'p_draft_id': draftParityDraftId,
  'p_store_id': draftParityStoreId,
  'p_customer': _expectedCustomerParams,
  'p_currency_code': 'VND',
  'p_order_note': 'Giao buoi chieu',
  'p_pricing_preview_token': 'preview-token-1',
  'p_needs_revalidation': true,
  'p_lines': _expectedLineParams,
  'p_expected_version': 3,
  'p_idempotency_key': 'k1',
  'p_payload_hash': 'hash-1',
};

const expectedCancelParams = <String, dynamic>{
  'p_tenant_id': draftParityTenantId,
  'p_actor_id': draftParityActorId,
  'p_draft_id': draftParityDraftId,
  'p_store_id': draftParityStoreId,
  'p_expected_version': 3,
  'p_idempotency_key': 'k1',
};

const expectedRestoreParams = <String, dynamic>{
  'p_tenant_id': draftParityTenantId,
  'p_actor_id': draftParityActorId,
  'p_draft_id': draftParityDraftId,
  'p_store_id': draftParityStoreId,
  'p_expected_version': 2,
};

const expectedRestoreParamsNoVersion = <String, dynamic>{
  'p_tenant_id': draftParityTenantId,
  'p_actor_id': draftParityActorId,
  'p_draft_id': draftParityDraftId,
  'p_store_id': draftParityStoreId,
};

const expectedListParams = <String, dynamic>{
  'p_tenant_id': draftParityTenantId,
  'p_actor_id': draftParityActorId,
  'p_store_id': draftParityStoreId,
  'p_cursor': 'cursor-1',
  'p_page_size': 10,
  'p_search': null,
  'p_created_by': null,
};

const expectedLegacyListParams = <String, dynamic>{
  'p_tenant_id': draftParityTenantId,
  'p_actor_id': draftParityActorId,
  'p_store_id': draftParityStoreId,
  'p_cursor': 'cursor-1',
  'p_page_size': 10,
};

Map<String, dynamic> sampleDraftJson({
  String id = 'draft-1',
  String createdByUserId = 'user-1',
  String? createdByName = 'Nguyen Van A',
}) => {
  'draft_id': id,
  'version': 2,
  'status': 'active',
  'store_id': 'store-1',
  'currency_code': 'VND',
  'total_amount_minor': 135000,
  'order_note': '  Giao buoi chieu  ',
  'pricing_preview_token': 'preview-token-1',
  'needs_revalidation': true,
  'saved_at': '2026-08-06T01:00:00.000Z',
  'saved_by_actor_id': 'actor-1',
  'created_by_user_id': createdByUserId,
  'created_by_name': createdByName,
  'customer': {
    'customer_id': 'customer-1',
    'display_name': 'Nguyen Van A',
    'phone_number': '0901234567',
    'tax_code': '0312345678',
    'buyer_type': 'individual',
  },
  'lines': [
    {
      'line_id': 'line-1',
      'product_id': 'product-1',
      'product_sku': 'SKU-1',
      'product_name': 'Thuoc A',
      'product_unit_id': 'unit-1',
      'unit_code': 'BOX',
      'unit_name': 'Hop',
      'quantity_micros': QuantityDto.scale,
      'applied_unit_price_minor': 120000,
      // số nguyên dạng double (Review Focus 3)
      'line_total_minor': 115000.0,
      'list_unit_price_minor': 130000,
      'manual_discount_minor': 5000,
      'pricing_source_code': 'list',
      'pricing_warning_codes': ['PRICE_STALE'],
      'pricing_blocking_codes': <String>[],
      'note': 'Line note',
      'needs_revalidation': false,
    },
    {
      'line_id': 'line-2',
      'product_id': 'product-2',
      'product_sku': 'SKU-2',
      'product_name': 'Thuoc B',
      'product_unit_id': 'unit-2',
      'unit_code': 'PCS',
      'unit_name': 'Vien',
      'quantity_micros': 2 * QuantityDto.scale,
      'applied_unit_price_minor': 10000,
      'line_total_minor': 20000,
      'needs_revalidation': true,
    },
  ],
};

Map<String, dynamic> sampleRestoreJson() => {
  'draft': sampleDraftJson(),
  'saved_at': '2026-08-06T01:00:00.000Z',
  'saved_by_actor_id': 'actor-1',
};

Map<String, dynamic> samplePageJson() => {
  'items': [sampleDraftJson(), sampleDraftJson(id: 'draft-2')],
  'has_more': true,
  'total_count': 42,
  'next_cursor': 'cursor-2',
};

void expectDraft(dynamic dto, {String id = 'draft-1'}) {
  expect(dto.draftId, id);
  expect(dto.version, 2);
  expect(dto.status, SalesDraftStatus.active);
  expect(dto.storeId, 'store-1');
  expect(dto.savedAt, DateTime.utc(2026, 8, 6, 1));
  expect(dto.savedByActorId, 'actor-1');
  expect(dto.orderNote, 'Giao buoi chieu');
  expect(dto.pricingPreviewToken, 'preview-token-1');
  expect(dto.needsRevalidation, isTrue);
  expect(dto.customer?.customerId, 'customer-1');
  expect(dto.customer?.displayName, 'Nguyen Van A');
  expect(dto.customer?.phoneNumber, '0901234567');
  expect(dto.customer?.taxCode, '0312345678');
  expect(dto.customer?.buyerType, 'individual');
  expect(dto.customer?.invoiceEmail, isNull);
  expect(dto.customer?.existingDebtMinor, 0);
  expect(dto.total.amountMinor, 135000);
  expect(dto.total.currencyCode, 'VND');
  expect(dto.lines, hasLength(2));
  final a = dto.lines[0];
  expect(a.lineId, 'line-1');
  expect(a.productSku, 'SKU-1');
  expect(a.unitName, 'Hop');
  expect(a.quantity.quantityMicros, QuantityDto.scale);
  expect(a.appliedUnitPrice.amountMinor, 120000);
  expect(a.lineTotal.amountMinor, 115000);
  expect(a.listUnitPrice?.amountMinor, 130000);
  expect(a.manualDiscountMinor, 5000);
  expect(a.manualUnitPriceMinor, isNull);
  expect(a.pricingSourceCode, 'list');
  expect(a.pricingWarningCodes, ['PRICE_STALE']);
  expect(a.pricingBlockingCodes, isEmpty);
  expect(a.note, 'Line note');
  expect(a.needsRevalidation, isFalse);
  final b = dto.lines[1];
  expect(b.lineId, 'line-2');
  expect(b.listUnitPrice, isNull);
  expect(b.pricingWarningCodes, isEmpty);
  expect(b.needsRevalidation, isTrue);
}

void expectRestore(dynamic dto) {
  expectDraft(dto.draft);
  expect(dto.savedAt, DateTime.utc(2026, 8, 6, 1));
  expect(dto.savedByActorId, 'actor-1');
}

void expectPage(dynamic dto) {
  if (dto is SalesDraftListPage) {
    expect(dto.items, hasLength(2));
    expectDraft(dto.items[0].draft);
    expectDraft(dto.items[1].draft, id: 'draft-2');
    expect(dto.items[0].createdByUserId, 'user-1');
    expect(dto.items[0].createdByName, 'Nguyen Van A');
    expect(dto.hasMore, isTrue);
    expect(dto.totalCount, 42);
    expect(dto.nextCursor, 'cursor-2');
    return;
  }
  expect(dto.page.items, hasLength(2));
  expectDraft(dto.page.items[0]);
  expectDraft(dto.page.items[1], id: 'draft-2');
  expect(dto.page.hasMore, isTrue);
  expect(dto.page.nextCursor, 'cursor-2');
}
