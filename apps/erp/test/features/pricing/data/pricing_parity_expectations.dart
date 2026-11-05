import 'package:flutter_test/flutter_test.dart';

const parityTenantId = 'tenant-1';
const parityActorId = 'user-1';
const parityStoreId = 'store-1';
const parityRuleId = '11111111-1111-4111-8111-111111111111';
const parityPaddedRuleId = '  11111111-1111-4111-8111-111111111111  ';
const parityCustomerId = '22222222-2222-4222-8222-222222222222';
const parityPaddedCustomerId = '  22222222-2222-4222-8222-222222222222  ';
const parityProductId = '33333333-3333-4333-8333-333333333333';
const parityPaddedProductId = '  33333333-3333-4333-8333-333333333333  ';
const parityProductUnitId = '44444444-4444-4444-8444-444444444444';
const parityPaddedProductUnitId = '  44444444-4444-4444-8444-444444444444  ';
const parityIdempotencyKey = 'idem-1';
const parityPaddedIdempotencyKey = '  idem-1  ';
const parityRawNote = '  ghi chú  ';
const parityNormalizedNote = 'ghi chú';
const parityBlankReason = '   ';
const parityPrecheckToken =
    '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

final parityBusinessDate = DateTime(2026, 11, 4);
final parityEffectiveFrom = DateTime(2026, 11, 4);
final parityEffectiveTo = DateTime(2026, 11, 20);
final parityEffectiveAt = DateTime.utc(2026, 11, 4, 3);

const expectedSearchParams = <String, dynamic>{
  'p_tenant_id': parityTenantId,
  'p_business_date': '2026-11-04',
  'p_q': 'vaccine',
  'p_quick_filter': 'below_floor',
  'p_statuses': ['applying', 'not_yet_effective'],
  'p_sources': ['manual', 'excel_import'],
  'p_customer_id': parityCustomerId,
  'p_product_id': parityProductId,
  'p_cursor': 'cursor-1',
  'p_limit': 25,
};

const expectedDetailParams = <String, dynamic>{
  'p_tenant_id': parityTenantId,
  'p_rule_id': parityRuleId,
  'p_business_date': '2026-11-04',
};

const expectedHistoryParams = <String, dynamic>{
  'p_tenant_id': parityTenantId,
  'p_rule_id': parityRuleId,
  'p_cursor': 'cursor-1',
  'p_limit': 25,
};

const expectedCreateParamsWithoutRuleId = <String, dynamic>{
  'p_tenant_id': parityTenantId,
  'p_customer_id': parityCustomerId,
  'p_product_id': parityProductId,
  'p_product_unit_id': parityProductUnitId,
  'p_rule_price_minor': 90000,
  'p_currency_code': 'VND',
  'p_effective_from': '2026-11-04',
  'p_effective_to': '2026-11-20',
  'p_note': parityNormalizedNote,
  'p_acknowledge_floor_warning': true,
  'p_acknowledge_overwrite': true,
  'p_idempotency_key': parityIdempotencyKey,
};

const expectedUpdateParamsWithoutRuleId = <String, dynamic>{
  'p_tenant_id': parityTenantId,
  'p_expected_version': 3,
  'p_rule_price_minor': 95000,
  'p_effective_from': '2026-11-04',
  'p_effective_to': '2026-11-20',
  'p_note': parityNormalizedNote,
  'p_acknowledge_floor_warning': true,
  'p_acknowledge_overwrite': true,
};

const expectedUpdateParams = <String, dynamic>{
  'p_tenant_id': parityTenantId,
  'p_rule_id': parityRuleId,
  'p_expected_version': 3,
  'p_rule_price_minor': 95000,
  'p_effective_from': '2026-11-04',
  'p_effective_to': '2026-11-20',
  'p_note': parityNormalizedNote,
  'p_acknowledge_floor_warning': true,
  'p_acknowledge_overwrite': true,
};

const expectedNewSearchParams = <String, dynamic>{
  ...expectedSearchParams,
  'p_sort': 'updated_at_desc',
  'p_updated_within_days': null,
};

const expectedNewUpdateParams = <String, dynamic>{
  ...expectedUpdateParams,
  'p_reason': null,
};

const expectedDisableParams = <String, dynamic>{
  'p_tenant_id': parityTenantId,
  'p_rule_id': parityRuleId,
  'p_expected_version': 3,
  'p_reason': null,
};

const expectedPrecheckReenableParams = <String, dynamic>{
  'p_tenant_id': parityTenantId,
  'p_rule_id': parityRuleId,
  'p_expected_version': 4,
  'p_business_date': '2026-11-04',
};

const expectedReenableParams = <String, dynamic>{
  'p_tenant_id': parityTenantId,
  'p_rule_id': parityRuleId,
  'p_expected_version': 4,
  'p_business_date': '2026-11-04',
  'p_precheck_token': parityPrecheckToken,
  'p_acknowledge_floor_warning': true,
  'p_acknowledge_overwrite': true,
};

const expectedResolveParams = <String, dynamic>{
  'p_tenant_id': parityTenantId,
  'p_customer_id': parityCustomerId,
  'p_product_id': parityProductId,
  'p_product_unit_id': parityProductUnitId,
  'p_business_date': '2026-11-04',
};

const expectedSalesPreviewParams = <String, dynamic>{
  'p_tenant_id': parityTenantId,
  'p_store_id': parityStoreId,
  'p_customer_id': parityCustomerId,
  'p_currency_code': 'VND',
  'p_context_version': 3,
  'p_effective_at': '2026-11-04T03:00:00.000Z',
  'p_lines': [
    {
      'local_line_id': 'line-1',
      'product_id': parityProductId,
      'product_unit_id': parityProductUnitId,
      'quantity_micros': 1000000,
      'manual_unit_price_minor': null,
      'manual_discount_minor': null,
      'manual_discount_basis_points': null,
    },
    {
      'local_line_id': 'line-2',
      'product_id': '55555555-5555-4555-8555-555555555555',
      'product_unit_id': '66666666-6666-4666-8666-666666666666',
      'quantity_micros': 2000000,
      'manual_unit_price_minor': 85000,
      'manual_discount_minor': null,
      'manual_discount_basis_points': null,
    },
  ],
};

const expectedSalesManualEvaluationParams = <String, dynamic>{
  'p_tenant_id': parityTenantId,
  'p_store_id': parityStoreId,
  'p_customer_id': parityCustomerId,
  'p_product_id': parityProductId,
  'p_product_unit_id': parityProductUnitId,
  'p_quantity_micros': 1000000,
  'p_currency_code': 'VND',
  'p_context_version': 3,
  'p_manual_unit_price_minor': 90000,
  'p_manual_discount_minor': null,
  'p_manual_discount_basis_points': null,
  'p_acknowledge_below_floor': false,
};

Map<String, dynamic> sampleDetailJson() => {
  'id': parityRuleId,
  'customer': {
    'customer_id': parityCustomerId,
    'display_name': 'Clinic A',
    'phone': '0901234567',
    'status': 'active',
  },
  'product_unit': {
    'product_id': parityProductId,
    'product_name': 'Vaccine',
    'product_unit_id': parityProductUnitId,
    'unit_name': 'Bottle',
    'sellable_status': 'active',
    'product_reference_id': 'VAC-001',
    'sku': 'VAC-BTL',
  },
  'price': {'amount_minor': 90000, 'currency_code': 'VND'},
  'effective_period': {
    'effective_from': '2026-11-04',
    'effective_to': '2026-11-20',
  },
  'rule_type': 'special_price',
  'source_type': 'manual',
  'persisted_status': 'active',
  'derived_status': 'applying',
  'note': parityNormalizedNote,
  'validation_outcome': {
    'outcome': 'warning',
    'warning_codes': ['below_floor_price'],
    'blocking_codes': <String>[],
    'list_price': {'amount_minor': 150000, 'currency_code': 'VND'},
    'floor_price': {'amount_minor': 100000, 'currency_code': 'VND'},
    'floor_price_hidden': false,
  },
  'reference_health': {
    'customer_state': 'valid',
    'product_unit_state': 'valid',
    'price_band_state': 'current',
    'issue_codes': <String>[],
    'used_stored_price_band_snapshot': false,
  },
  'source_trace': {
    'hidden': false,
    'source_import_id': 'import-1',
    'source_import_row_id': 'row-1',
    'source_order_id': 'order-1',
    'source_order_line_id': 'line-1',
    'source_memory_request_id': 'request-1',
  },
  'created_by': 'user-1',
  'created_at': '2026-11-04T00:00:00Z',
  'updated_by': 'user-1',
  'updated_at': '2026-11-04T10:30:00+07:00',
  'version': 3,
  'available_actions': ['edit', 'disable', 'history'],
  'disabled_at': null,
  'disabled_by': null,
  'disabled_reason': null,
  'deleted_at': null,
};

Map<String, dynamic> sampleCreateResultJson() => {
  'rule': sampleDetailJson(),
  'warnings': [
    {
      'code': 'below_floor_price',
      'field': 'rulePriceMinor',
      'details': {'floorMinor': 100000},
    },
  ],
};

Map<String, dynamic> sampleSearchResultJson() => {
  'items': [
    {
      'id': parityRuleId,
      'customer': {
        'customer_id': parityCustomerId,
        'display_name': 'Clinic A',
        'phone': '0901234567',
        'status': 'active',
      },
      'product_unit': {
        'product_id': parityProductId,
        'product_name': 'Vaccine',
        'product_unit_id': parityProductUnitId,
        'unit_name': 'Bottle',
        'sellable_status': 'active',
        'product_reference_id': 'VAC-001',
        'sku': 'VAC-BTL',
      },
      'price': {'amount_minor': 125000, 'currency_code': 'VND'},
      'effective_period': {
        'effective_from': '2026-11-01',
        'effective_to': '2026-11-30',
      },
      'rule_type': 'special_price',
      'source_type': 'manual',
      'persisted_status': 'active',
      'derived_status': 'applying',
      'validation_outcome': {
        'outcome': 'warning',
        'warning_codes': ['below_floor_price'],
        'blocking_codes': <String>[],
        'list_price': {'amount_minor': 150000, 'currency_code': 'VND'},
        'floor_price': null,
        'floor_price_hidden': true,
      },
      'updated_at': '2026-11-04T10:30:00+07:00',
    },
    {
      'id': 'rule-2',
      'customer': {
        'customer_id': 'customer-2',
        'display_name': 'Clinic B',
        'status': 'active',
      },
      'product_unit': {
        'product_id': 'product-2',
        'product_name': 'Medicine',
        'product_unit_id': 'unit-2',
        'unit_name': 'Box',
        'sellable_status': 'active',
        'product_reference_id': null,
        'sku': null,
      },
      'price': {'amount_minor': 200000, 'currency_code': 'VND'},
      'effective_period': {
        'effective_from': '2026-12-01',
        'effective_to': null,
      },
      'rule_type': 'special_price',
      'source_type': 'excel_import',
      'persisted_status': 'active',
      'derived_status': 'not_yet_effective',
      'validation_outcome': {
        'outcome': 'notChecked',
        'warning_codes': <String>[],
        'blocking_codes': <String>[],
        'list_price': null,
        'floor_price': null,
        'floor_price_hidden': false,
      },
      'updated_at': '2026-11-03T00:00:00Z',
    },
  ],
  'next_cursor': 'cursor-2',
  'has_more': true,
  'available_actions': ['create_manual', 'import'],
  'total_count': 2,
};

Map<String, dynamic> sampleHistoryPageJson() => {
  'items': [
    {
      'id': 'act-1',
      'activity_type': 'memory_updated',
      'actor': {
        'actor_id': '00000000-0000-4000-8000-000000000099',
        'display_name': '5ef27a1c',
        'is_system_actor': false,
      },
      'source_type': 'sales_order',
      'old_value': {
        'version': 3,
        'nested': {'a': 1},
      },
      'new_value': {
        'version': 4,
        'tags': ['x'],
      },
      'reason': 'Cập nhật từ đơn',
      'source_trace': {
        'import_id': null,
        'import_row_id': null,
        'order_id': '00000000-0000-4000-8000-000000000201',
        'order_line_id': '00000000-0000-4000-8000-000000000202',
        'memory_request_id': '00000000-0000-4000-8000-000000000203',
        'sold_at': '2026-11-04T09:00:00+07:00',
      },
      'sensitive_values_hidden': true,
      'created_at': '2026-11-04T09:30:00.123456Z',
    },
    {
      'id': 'act-2',
      'activity_type': 'created',
      'actor': {
        'actor_id': null,
        'display_name': 'System/Migration',
        'is_system_actor': true,
      },
      'source_type': 'migration',
      'old_value': null,
      'new_value': {'version': 1},
      'reason': null,
      'source_trace': {
        'import_id': null,
        'import_row_id': null,
        'order_id': null,
        'order_line_id': null,
        'memory_request_id': null,
        'sold_at': null,
      },
      'sensitive_values_hidden': false,
      'created_at': '2026-11-01T00:00:00Z',
    },
  ],
  'next_cursor': 'hist-cursor-2',
  'has_more': true,
};

Map<String, dynamic> sampleReenablePrecheckJson() => {
  'precheck_token': parityPrecheckToken,
  'rule_version': 4,
  'business_date': '2026-11-04',
  'validation_outcome': {
    'outcome': 'valid',
    'warning_codes': <String>[],
    'blocking_codes': <String>[],
    'list_price': {'amount_minor': 150000, 'currency_code': 'VND'},
    'floor_price': {'amount_minor': 125000, 'currency_code': 'VND'},
    'floor_price_hidden': false,
  },
};

Map<String, dynamic> sampleResolveFoundJson() => {
  'rule': {
    'rule_id': parityRuleId,
    'price': {'amount_minor': 90000, 'currency_code': 'VND'},
    'effective_period': {
      'effective_from': '2026-11-04',
      'effective_to': '2026-11-20',
    },
    'source_type': 'manual',
    'version': 3,
  },
};

Map<String, dynamic> sampleResolveNullJson() => {'rule': null};

Map<String, dynamic> sampleSalesPreviewJson() => {
  'context_version': 3,
  'preview_token': 'preview-token',
  'currency_code': 'VND',
  'lines': [
    {
      'local_line_id': 'line-1',
      'applied_unit_price_minor': 100000,
      'discount_minor': 0,
      'line_total_minor': 100000,
      'source_code': 'LIST_PRICE',
      'list_price_minor': 100000,
      'floor_price_minor': 90000,
      'warning_codes': <String>[],
      'blocking_codes': <String>[],
    },
    {
      'local_line_id': 'line-2',
      'applied_unit_price_minor': 85000,
      'discount_minor': 5000,
      'line_total_minor': 170000,
      'source_code': 'MANUAL_OVERRIDE',
      'list_price_minor': 90000,
      'floor_price_minor': null,
      'warning_codes': ['BELOW_FLOOR'],
      'blocking_codes': <String>[],
    },
  ],
};

Map<String, dynamic> sampleSalesManualEvaluationJson() => {
  'allowed': true,
  'requires_acknowledgement': true,
  'normalized_unit_price_minor': 90000,
  'floor_price_minor': 95000,
  'can_view_floor': true,
  'warning_codes': ['BELOW_FLOOR'],
  'blocking_code': null,
  'message': 'Below floor',
};

void expectDetail(dynamic dto) {
  expect(dto.id, parityRuleId);
  expect(dto.customer.customerId, parityCustomerId);
  expect(dto.customer.displayName, 'Clinic A');
  expect(dto.customer.phone, '0901234567');
  expect(dto.customer.status, 'active');
  expect(dto.productUnit.productId, parityProductId);
  expect(dto.productUnit.productName, 'Vaccine');
  expect(dto.productUnit.productUnitId, parityProductUnitId);
  expect(dto.productUnit.unitName, 'Bottle');
  expect(dto.productUnit.sellableStatus, 'active');
  expect(dto.productUnit.productReferenceId, 'VAC-001');
  expect(dto.productUnit.sku, 'VAC-BTL');
  expect(dto.price.amountMinor, 90000);
  expect(dto.price.currencyCode, 'VND');
  expect(dto.effectivePeriod.effectiveFrom, DateTime.utc(2026, 11, 4));
  expect(dto.effectivePeriod.effectiveTo, DateTime.utc(2026, 11, 20));
  expect((dto.ruleType as Enum).name, 'specialPrice');
  expect((dto.sourceType as Enum).name, 'manual');
  expect((dto.persistedStatus as Enum).name, 'active');
  expect((dto.derivedStatus as Enum).name, 'applying');
  expect(dto.note, parityNormalizedNote);
  expect(dto.validationOutcome.outcome, 'warning');
  expect(dto.validationOutcome.warningCodes, ['below_floor_price']);
  expect(dto.validationOutcome.blockingCodes, isEmpty);
  expect(dto.validationOutcome.listPrice?.amountMinor, 150000);
  expect(dto.validationOutcome.floorPrice?.amountMinor, 100000);
  expect(dto.validationOutcome.floorPriceHidden, isFalse);
  expect((dto.referenceHealth.customerState as Enum).name, 'valid');
  expect((dto.referenceHealth.productUnitState as Enum).name, 'valid');
  expect((dto.referenceHealth.priceBandState as Enum).name, 'current');
  expect(dto.referenceHealth.issueCodes, isEmpty);
  expect(dto.referenceHealth.usedStoredPriceBandSnapshot, isFalse);
  expect(dto.sourceTrace.hidden, isFalse);
  expect(dto.sourceTrace.sourceImportId, 'import-1');
  expect(dto.sourceTrace.sourceImportRowId, 'row-1');
  expect(dto.sourceTrace.sourceOrderId, 'order-1');
  expect(dto.sourceTrace.sourceOrderLineId, 'line-1');
  expect(dto.sourceTrace.sourceMemoryRequestId, 'request-1');
  expect(dto.createdBy, 'user-1');
  expect(dto.createdAt, DateTime.utc(2026, 11, 4));
  expect(dto.updatedBy, 'user-1');
  expect(dto.updatedAt, DateTime.utc(2026, 11, 4, 3, 30));
  expect(dto.version, 3);
  expect(dto.availableActions, ['edit', 'disable', 'history']);
  expect(dto.disabledAt, isNull);
  expect(dto.disabledBy, isNull);
  expect(dto.disabledReason, isNull);
  expect(dto.deletedAt, isNull);
}

void expectCreateResult(dynamic result) {
  expectDetail(result.rule);
  expect(result.warnings, hasLength(1));
  final warning = result.warnings.single;
  expect(warning.code, 'below_floor_price');
  expect(warning.field, 'rulePriceMinor');
  expect(warning.details, {'floorMinor': 100000});
}

void expectSearchResult(dynamic result) {
  expect(result.page.hasMore, isTrue);
  expect(result.page.nextCursor, 'cursor-2');
  expect(result.availableActions, ['create_manual', 'import']);
  expect(result.page.items, hasLength(2));

  final first = result.page.items[0];
  expect(first.id, parityRuleId);
  expect(first.customer.customerId, parityCustomerId);
  expect(first.productUnit.productReferenceId, 'VAC-001');
  expect(first.productUnit.sku, 'VAC-BTL');
  expect(first.price.amountMinor, 125000);
  expect((first.sourceType as Enum).name, 'manual');
  expect((first.derivedStatus as Enum).name, 'applying');
  expect(first.validationOutcome.warningCodes, ['below_floor_price']);
  expect(first.validationOutcome.floorPrice, isNull);
  expect(first.validationOutcome.floorPriceHidden, isTrue);
  expect(first.updatedAt, DateTime.utc(2026, 11, 4, 3, 30));

  final second = result.page.items[1];
  expect(second.id, 'rule-2');
  expect((second.sourceType as Enum).name, 'excelImport');
  expect((second.derivedStatus as Enum).name, 'notYetEffective');
  expect(second.effectivePeriod.effectiveTo, isNull);
}

void expectHistoryPage(dynamic page) {
  expect(page.hasMore, isTrue);
  expect(page.nextCursor, 'hist-cursor-2');
  expect(page.items, hasLength(2));

  final first = page.items[0];
  expect(first.id, 'act-1');
  expect((first.activityType as Enum).name, 'memoryUpdated');
  expect(first.actor.actorId, '00000000-0000-4000-8000-000000000099');
  expect(first.actor.displayName, '5ef27a1c');
  expect(first.actor.isSystemActor, isFalse);
  expect((first.sourceType as Enum).name, 'salesOrder');
  expect(first.reason, 'Cập nhật từ đơn');
  expect(first.sourceTrace.orderId, '00000000-0000-4000-8000-000000000201');
  expect(first.sourceTrace.soldAt, DateTime.utc(2026, 11, 4, 2));
  expect(first.sensitiveValuesHidden, isTrue);
  expect(first.createdAt.isUtc, isTrue);
  expect(() => (first.newValue as Map)['version'] = 9, throwsUnsupportedError);

  final second = page.items[1];
  expect(second.id, 'act-2');
  expect((second.activityType as Enum).name, 'created');
  expect(second.actor.actorId, isNull);
  expect(second.actor.displayName, 'System/Migration');
  expect(second.actor.isSystemActor, isTrue);
  expect((second.sourceType as Enum).name, 'migration');
  expect(second.oldValue, isNull);
  expect(second.sensitiveValuesHidden, isFalse);
}

void expectReenablePrecheck(dynamic dto) {
  expect(dto.precheckToken, parityPrecheckToken);
  expect(dto.ruleVersion, 4);
  expect(dto.businessDate, DateTime.utc(2026, 11, 4));
  expect(dto.validationOutcome.outcome, 'valid');
  expect(dto.validationOutcome.listPrice?.amountMinor, 150000);
  expect(dto.validationOutcome.floorPrice?.amountMinor, 125000);
  expect(dto.validationOutcome.floorPriceHidden, isFalse);
}

void expectResolveFound(dynamic dto) {
  final rule = dto.rule;
  expect(rule, isNotNull);
  expect(rule.ruleId, parityRuleId);
  expect(rule.price.amountMinor, 90000);
  expect(rule.price.currencyCode, 'VND');
  expect(rule.effectivePeriod.effectiveFrom, DateTime.utc(2026, 11, 4));
  expect(rule.effectivePeriod.effectiveTo, DateTime.utc(2026, 11, 20));
  expect((rule.sourceType as Enum).name, 'manual');
  expect(rule.version, 3);
}

void expectResolveNull(dynamic dto) {
  expect(dto.rule, isNull);
}

void expectSalesPreview(dynamic dto) {
  expect(dto.contextVersion, 3);
  expect(dto.previewToken, 'preview-token');
  expect(dto.currencyCode, 'VND');
  expect(dto.lines, hasLength(2));

  final first = dto.lines[0];
  expect(first.localLineId, 'line-1');
  expect(first.appliedUnitPriceMinor, 100000);
  expect(first.discountMinor, 0);
  expect(first.lineTotalMinor, 100000);
  expect(first.sourceCode, 'LIST_PRICE');
  expect(first.listPriceMinor, 100000);
  expect(first.floorPriceMinor, 90000);
  expect(first.warningCodes, isEmpty);
  expect(first.blockingCodes, isEmpty);

  final second = dto.lines[1];
  expect(second.localLineId, 'line-2');
  expect(second.appliedUnitPriceMinor, 85000);
  expect(second.discountMinor, 5000);
  expect(second.lineTotalMinor, 170000);
  expect(second.sourceCode, 'MANUAL_OVERRIDE');
  expect(second.listPriceMinor, 90000);
  expect(second.floorPriceMinor, isNull);
  expect(second.warningCodes, ['BELOW_FLOOR']);
  expect(second.blockingCodes, isEmpty);
}

void expectSalesManualEvaluation(dynamic dto) {
  expect(dto.allowed, isTrue);
  expect(dto.requiresAcknowledgement, isTrue);
  expect(dto.normalizedUnitPriceMinor, 90000);
  expect(dto.floorPriceMinor, 95000);
  expect(dto.canViewFloor, isTrue);
  expect(dto.warningCodes, ['BELOW_FLOOR']);
  expect(dto.blockingCode, isNull);
  expect(dto.message, 'Below floor');
}

