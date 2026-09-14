import 'package:test/test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_sales_infrastructure/src/domain/sales_order_draft/sales_order_draft_rpc_mapper.dart';

void main() {
  group('SalesOrderDraftRpcMapper', () {
    test('save params send store scope and full line snapshot', () {
      final params = SalesOrderDraftRpcMapper.saveParams(_saveCommand());

      expect(params['p_tenant_id'], 'tenant-1');
      expect(params['p_actor_id'], 'actor-1');
      expect(params['p_store_id'], 'store-1');
      expect(params['p_currency_code'], 'VND');
      expect(params['p_order_note'], 'Giao buoi chieu');
      expect(params['p_pricing_preview_token'], 'preview-token-1');
      expect(params['p_needs_revalidation'], isFalse);
      expect(params['p_idempotency_key'], 'idem-1');
      expect(params['p_customer'], <String, dynamic>{
        'customer_id': 'customer-1',
        'display_name': 'Nguyen Van A',
        'phone_number': '0901234567',
      });

      final line = (params['p_lines'] as List).single as Map<String, dynamic>;
      expect(line['product_id'], 'product-1');
      expect(line['product_sku'], 'SKU-1');
      expect(line['product_name'], 'Thuoc A');
      expect(line['product_unit_id'], 'unit-1');
      expect(line['unit_code'], 'BOX');
      expect(line['unit_name'], 'Hop');
      expect(line['quantity_micros'], QuantityDto.scale);
      expect(line['applied_unit_price_minor'], 120000);
      expect(line['line_total_minor'], 115000);
      expect(line['list_unit_price_minor'], 130000);
      expect(line['manual_discount_minor'], 5000);
      expect(line['pricing_source_code'], 'list');
      expect(line['pricing_warning_codes'], ['PRICE_STALE']);
      expect(line['pricing_blocking_codes'], isEmpty);
      expect(line['note'], 'Line note');
      expect(line['needs_revalidation'], isFalse);
      expect(line.containsKey('unit_price_minor'), isFalse);
      expect(line.containsKey('floor_price_minor'), isFalse);
      expect(line.containsKey('stock_on_hand'), isFalse);
    });

    test('save params send null customer for walk-in', () {
      final params = SalesOrderDraftRpcMapper.saveParams(
        SaveSalesOrderDraftCommand(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          storeId: 'store-1',
          currencyCode: 'VND',
          lines: _lines(),
          idempotencyKey: 'idem-walk-in',
        ),
      );

      expect(params['p_customer'], isNull);
      expect(params.containsKey('p_customer_id'), isFalse);
    });

    test('update/cancel/list/restore params always include p_store_id', () {
      final update = SalesOrderDraftRpcMapper.updateParams(
        UpdateSalesOrderDraftCommand(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          draftId: 'draft-1',
          storeId: 'store-1',
          currencyCode: 'VND',
          orderNote: 'Giao buoi chieu',
          pricingPreviewToken: 'preview-token-1',
          lines: _lines(),
          idempotencyKey: 'idem-2',
          expectedVersion: 3,
        ),
      );
      expect(update['p_store_id'], 'store-1');
      expect(update['p_draft_id'], 'draft-1');
      expect(update['p_expected_version'], 3);
      expect(update['p_currency_code'], 'VND');
      expect(
        (update['p_lines'] as List).single['applied_unit_price_minor'],
        120000,
      );
      expect((update['p_lines'] as List).single['product_name'], 'Thuoc A');
      expect((update['p_lines'] as List).single['needs_revalidation'], isFalse);

      final cancel = SalesOrderDraftRpcMapper.cancelParams(
        CancelSalesOrderDraftCommand(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          draftId: 'draft-1',
          storeId: 'store-1',
          idempotencyKey: 'idem-3',
          expectedVersion: 3,
        ),
      );
      expect(cancel['p_store_id'], 'store-1');
      expect(cancel['p_draft_id'], 'draft-1');

      final list = SalesOrderDraftRpcMapper.listParams(
        ListSalesOrderDraftsQuery(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          storeId: 'store-1',
          cursor: '0',
          pageSize: 10,
        ),
      );
      expect(list['p_store_id'], 'store-1');
      expect(list['p_page_size'], 10);

      final restore = SalesOrderDraftRpcMapper.restoreParams(
        GetSalesOrderDraftForRestoreQuery(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          draftId: 'draft-1',
          storeId: 'store-1',
          expectedSourceVersion: 2,
        ),
      );
      expect(restore['p_store_id'], 'store-1');
      expect(restore['p_expected_version'], 2);
    });

    test('draft result json maps lossless snapshot fields', () {
      final dto = SalesOrderDraftRpcMapper.draftFromJson(_draftJson());

      expect(dto.draftId, 'draft-1');
      expect(dto.storeId, 'store-1');
      expect(dto.status, SalesDraftStatus.active);
      expect(dto.customer?.customerId, 'customer-1');
      expect(dto.customer?.displayName, 'Nguyen Van A');
      expect(dto.customer?.existingDebtMinor, 0);
      expect(dto.orderNote, 'Giao buoi chieu');
      expect(dto.pricingPreviewToken, 'preview-token-1');
      expect(dto.needsRevalidation, isFalse);
      expect(dto.lines.single.productSku, 'SKU-1');
      expect(dto.lines.single.productName, 'Thuoc A');
      expect(dto.lines.single.appliedUnitPrice.amountMinor, 120000);
      expect(dto.lines.single.lineTotal.amountMinor, 115000);
      expect(dto.lines.single.listUnitPrice?.amountMinor, 130000);
      expect(dto.lines.single.manualDiscountMinor, 5000);
      expect(dto.lines.single.pricingSourceCode, 'list');
      expect(dto.lines.single.pricingWarningCodes, ['PRICE_STALE']);
      expect(dto.lines.single.needsRevalidation, isFalse);
      expect(dto.total.amountMinor, 115000);
    });

    test('response decoding rejects missing required line snapshot fields', () {
      final incomplete = _draftJson();
      final lines = (incomplete['lines'] as List).cast<Map<String, dynamic>>();
      lines.single.remove('product_name');

      expect(
        () => SalesOrderDraftRpcMapper.draftFromJson(incomplete),
        throwsA(isA<FormatException>()),
      );
    });

    test('response decoding rejects missing store_id without fake fallback', () {
      final incomplete = _draftJson()..remove('store_id');

      expect(
        () => SalesOrderDraftRpcMapper.draftFromJson(incomplete),
        throwsA(isA<FormatException>()),
      );
    });

    test('response decoding rejects ID-as-name style missing sku/name', () {
      final incomplete = _draftJson();
      final line = (incomplete['lines'] as List).single as Map<String, dynamic>;
      line.remove('product_sku');
      line.remove('unit_code');

      expect(
        () => SalesOrderDraftRpcMapper.draftFromJson(incomplete),
        throwsA(isA<FormatException>()),
      );
    });

    test('restore json preserves audit fields', () {
      final dto = SalesOrderDraftRpcMapper.restoreFromJson({
        'draft': _draftJson(),
        'saved_at': '2026-08-06T01:00:00.000Z',
        'saved_by_actor_id': 'actor-1',
      });

      expect(dto.draft.draftId, 'draft-1');
      expect(dto.draft.storeId, 'store-1');
      expect(dto.savedAt, DateTime.utc(2026, 8, 6, 1));
      expect(dto.savedByActorId, 'actor-1');
    });

    test('list json maps cursor page', () {
      final dto = SalesOrderDraftRpcMapper.pageFromJson({
        'items': [_draftJson()],
        'has_more': true,
        'next_cursor': 'cursor-2',
      });

      expect(dto.page.items.single.draftId, 'draft-1');
      expect(dto.page.items.single.storeId, 'store-1');
      expect(dto.page.hasMore, isTrue);
      expect(dto.page.nextCursor, 'cursor-2');
    });
  });
}

SaveSalesOrderDraftCommand _saveCommand() {
  return SaveSalesOrderDraftCommand(
    tenantId: 'tenant-1',
    actorId: 'actor-1',
    storeId: 'store-1',
    customer: const CustomerSnapshotDto(
      customerId: 'customer-1',
      displayName: 'Nguyen Van A',
      phoneNumber: '0901234567',
      existingDebtMinor: 0,
    ),
    currencyCode: ' vnd ',
    orderNote: 'Giao buoi chieu',
    pricingPreviewToken: 'preview-token-1',
    needsRevalidation: false,
    lines: _lines(),
    idempotencyKey: ' idem-1 ',
  );
}

List<SalesOrderDraftLineInput> _lines() {
  return [
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
      needsRevalidation: false,
    ),
  ];
}

Map<String, dynamic> _draftJson() {
  return {
    'draft_id': 'draft-1',
    'version': 1,
    'status': 'active',
    'store_id': 'store-1',
    'currency_code': 'VND',
    'total_amount_minor': 115000,
    'order_note': 'Giao buoi chieu',
    'pricing_preview_token': 'preview-token-1',
    'needs_revalidation': false,
    'saved_at': '2026-08-06T01:00:00.000Z',
    'saved_by_actor_id': 'actor-1',
    'customer': {
      'customer_id': 'customer-1',
      'display_name': 'Nguyen Van A',
      'phone_number': '0901234567',
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
        'line_total_minor': 115000,
        'list_unit_price_minor': 130000,
        'manual_discount_minor': 5000,
        'pricing_source_code': 'list',
        'pricing_warning_codes': ['PRICE_STALE'],
        'pricing_blocking_codes': <String>[],
        'note': 'Line note',
        'needs_revalidation': false,
      },
    ],
  };
}
