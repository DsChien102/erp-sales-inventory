// ignore_for_file: implementation_imports, depend_on_referenced_packages

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/pricing/data/customer_price_rule_repository.dart';
import 'package:erp/features/pricing/data/mappers/customer_price_rule_json.dart';
import 'package:erp/features/pricing/data/mappers/sales_pricing_json.dart';
import 'package:erp/features/pricing/data/models.dart' as new_models;
import 'package:erp/features/pricing/data/sales_pricing_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'pricing_parity_expectations.dart';

void main() {
  group('new (json)', () {
    test('parse_detail', () {
      final dto = CustomerPriceRuleJson.detail(sampleDetailJson());
      expectDetail(dto);
    });

    test('parse_create_result', () {
      final dto = CustomerPriceRuleJson.createResult(sampleCreateResultJson());
      expectCreateResult(dto);
    });

    test('parse_search_result', () {
      final dto = CustomerPriceRuleJson.searchResult(sampleSearchResultJson());
      expectSearchResult(dto);
    });

    test('parse_history_page', () {
      final page = CustomerPriceRuleJson.historyPage(sampleHistoryPageJson());
      expectHistoryPage(page);
    });

    test('parse_reenable_precheck', () {
      final dto = CustomerPriceRuleJson.precheck(sampleReenablePrecheckJson());
      expectReenablePrecheck(dto);
    });

    test('parse_resolve_found', () {
      final dto = CustomerPriceRuleJson.resolveResult(sampleResolveFoundJson());
      expectResolveFound(dto);
    });

    test('parse_resolve_null', () {
      final dto = CustomerPriceRuleJson.resolveResult(sampleResolveNullJson());
      expectResolveNull(dto);
    });

    test('parse_sales_preview', () {
      final dto = SalesPricingJson.preview(
        sampleSalesPreviewJson(),
        expectedContextVersion: 3,
        expectedCurrencyCode: 'VND',
        expectedLocalLineIds: const ['line-1', 'line-2'],
      );
      expectSalesPreview(dto);
    });

    test('parse_sales_manual_evaluation', () {
      final dto = SalesPricingJson.manualEvaluation(
        sampleSalesManualEvaluationJson(),
      );
      expectSalesManualEvaluation(dto);
    });

    test('preview_rejects_mismatched_context', () {
      expect(
        () => SalesPricingJson.preview(
          sampleSalesPreviewJson()..['context_version'] = 99,
          expectedContextVersion: 3,
          expectedCurrencyCode: 'VND',
          expectedLocalLineIds: const ['line-1', 'line-2'],
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('money_accepts_integer_double_and_rejects_fractional_double', () {
      final json = sampleDetailJson()
        ..['price'] = {'amount_minor': 1200.0, 'currency_code': 'VND'};
      final dto = CustomerPriceRuleJson.detail(json);
      expect(dto.price.amountMinor, 1200);

      final fractional = sampleDetailJson()
        ..['price'] = {'amount_minor': 1200.5, 'currency_code': 'VND'};
      expect(
        () => CustomerPriceRuleJson.detail(fractional),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('new (CustomerPriceRuleRepository)', () {
    late _RecordingRpc rpc;
    late CustomerPriceRuleRepository repo;

    setUp(() {
      rpc = _RecordingRpc();
      repo = CustomerPriceRuleRepository(
        rpc: rpc,
        tenantId: () async => parityTenantId,
      );
    });

    test('params_search_customer_price_rules', () async {
      rpc.nextCallResult = sampleSearchResultJson();
      final result = await repo.search(
        businessDate: parityBusinessDate,
        q: '  vaccine  ',
        quickFilter: new_models.CustomerPriceRuleQuickFilter.belowFloor,
        statuses: const [
          new_models.CustomerPriceRuleDerivedStatus.applying,
          new_models.CustomerPriceRuleDerivedStatus.notYetEffective,
        ],
        sources: const [
          new_models.CustomerPriceRuleSourceType.manual,
          new_models.CustomerPriceRuleSourceType.excelImport,
        ],
        customerId: parityCustomerId,
        productId: parityProductId,
        cursor: '  cursor-1  ',
        limit: 25,
      );
      expect(rpc.calls, hasLength(1));
      expect(rpc.calls.single.schema, 'pricing');
      expect(rpc.calls.single.rpc, 'search_customer_price_rules');
      expect(rpc.calls.single.params, equals(expectedNewSearchParams));
      expectSearchResult(result);
    });

    test('params_get_customer_price_rule_detail', () async {
      rpc.nextCallResult = sampleDetailJson();
      final result = await repo.getDetail(
        ruleId: parityRuleId,
        businessDate: parityBusinessDate,
      );
      expect(rpc.calls, hasLength(1));
      expect(rpc.calls.single.schema, 'pricing');
      expect(rpc.calls.single.rpc, 'get_customer_price_rule_detail');
      expect(rpc.calls.single.params, equals(expectedDetailParams));
      expectDetail(result);
    });

    test('params_get_customer_price_rule_history', () async {
      rpc.nextCallResult = sampleHistoryPageJson();
      final result = await repo.getHistory(
        ruleId: parityRuleId,
        cursor: '  cursor-1  ',
        limit: 25,
      );
      expect(rpc.calls, hasLength(1));
      expect(rpc.calls.single.schema, 'pricing');
      expect(rpc.calls.single.rpc, 'get_customer_price_rule_history');
      expect(rpc.calls.single.params, equals(expectedHistoryParams));
      expectHistoryPage(result);
    });

    test('params_create_customer_price_rule', () async {
      rpc.nextCallResult = sampleCreateResultJson();
      final result = await repo.create(
        customerId: parityCustomerId,
        productId: parityProductId,
        productUnitId: parityProductUnitId,
        rulePriceMinor: 90000,
        currencyCode: 'VND',
        effectiveFrom: parityEffectiveFrom,
        effectiveTo: parityEffectiveTo,
        note: parityRawNote,
        acknowledgeFloorWarning: true,
        acknowledgeOverwrite: true,
        idempotencyKey: parityPaddedIdempotencyKey,
      );
      expect(rpc.calls, hasLength(1));
      expect(rpc.calls.single.schema, 'pricing');
      expect(rpc.calls.single.rpc, 'create_customer_price_rule');
      final params = rpc.calls.single.params!;
      final ruleId = params['p_rule_id'] as String?;
      expect(ruleId, isNotNull);
      expect(Uuid.isValidUUID(fromString: ruleId!), isTrue);
      final withoutRuleId = Map<String, dynamic>.of(params)
        ..remove('p_rule_id');
      expect(withoutRuleId, equals(expectedCreateParamsWithoutRuleId));
      expectCreateResult(result);
    });

    test('params_update_customer_price_rule', () async {
      rpc.nextCallResult = sampleDetailJson();
      final result = await repo.update(
        ruleId: parityRuleId,
        expectedVersion: 3,
        rulePriceMinor: 95000,
        effectiveFrom: parityEffectiveFrom,
        effectiveTo: parityEffectiveTo,
        note: parityRawNote,
        acknowledgeFloorWarning: true,
        acknowledgeOverwrite: true,
      );
      expect(rpc.calls, hasLength(1));
      expect(rpc.calls.single.schema, 'pricing');
      expect(rpc.calls.single.rpc, 'update_customer_price_rule');
      expect(rpc.calls.single.params, equals(expectedNewUpdateParams));
      expectDetail(result);
    });

    test('params_disable_customer_price_rule', () async {
      rpc.nextCallResult = sampleDetailJson();
      final result = await repo.disable(
        ruleId: parityPaddedRuleId,
        expectedVersion: 3,
        reason: parityBlankReason,
      );
      expect(rpc.calls, hasLength(1));
      expect(rpc.calls.single.schema, 'pricing');
      expect(rpc.calls.single.rpc, 'disable_customer_price_rule');
      expect(rpc.calls.single.params, equals(expectedDisableParams));
      expectDetail(result);
    });

    test('params_precheck_customer_price_rule_reenable', () async {
      rpc.nextCallResult = sampleReenablePrecheckJson();
      final result = await repo.precheckReenable(
        ruleId: parityRuleId,
        expectedVersion: 4,
        businessDate: parityBusinessDate,
      );
      expect(rpc.calls, hasLength(1));
      expect(rpc.calls.single.schema, 'pricing');
      expect(rpc.calls.single.rpc, 'precheck_customer_price_rule_reenable');
      expect(rpc.calls.single.params, equals(expectedPrecheckReenableParams));
      expectReenablePrecheck(result);
    });

    test('params_reenable_customer_price_rule', () async {
      rpc.nextCallResult = sampleDetailJson();
      final result = await repo.reenable(
        ruleId: parityPaddedRuleId,
        expectedVersion: 4,
        businessDate: parityBusinessDate,
        precheckToken: parityPrecheckToken,
        acknowledgeFloorWarning: true,
        acknowledgeOverwrite: true,
      );
      expect(rpc.calls, hasLength(1));
      expect(rpc.calls.single.schema, 'pricing');
      expect(rpc.calls.single.rpc, 'reenable_customer_price_rule');
      expect(rpc.calls.single.params, equals(expectedReenableParams));
      expectDetail(result);
    });

    test('params_resolve_applicable_customer_price_rule', () async {
      rpc.nextCallResult = sampleResolveFoundJson();
      final result = await repo.resolveApplicable(
        customerId: parityPaddedCustomerId,
        productId: parityPaddedProductId,
        productUnitId: parityPaddedProductUnitId,
        businessDate: parityBusinessDate,
      );
      expect(rpc.calls, hasLength(1));
      expect(rpc.calls.single.schema, 'pricing');
      expect(rpc.calls.single.rpc, 'resolve_applicable_customer_price_rule');
      expect(rpc.calls.single.params, equals(expectedResolveParams));
      expectResolveFound(result);
    });

    test('params_create_customer_price_rule_lowercase_currency', () async {
      rpc.nextCallResult = sampleCreateResultJson();
      final result = await repo.create(
        customerId: parityCustomerId,
        productId: parityProductId,
        productUnitId: parityProductUnitId,
        rulePriceMinor: 90000,
        currencyCode: ' vnd ',
        effectiveFrom: parityEffectiveFrom,
        effectiveTo: parityEffectiveTo,
        note: parityRawNote,
        acknowledgeFloorWarning: true,
        acknowledgeOverwrite: true,
        idempotencyKey: parityPaddedIdempotencyKey,
      );
      expect(rpc.calls, hasLength(1));
      final params = rpc.calls.single.params!;
      final withoutRuleId = Map<String, dynamic>.of(params)
        ..remove('p_rule_id');
      expect(withoutRuleId, equals(expectedCreateParamsWithoutRuleId));
      expectCreateResult(result);
    });
  });

  group('new (SalesPricingRepository)', () {
    late _RecordingRpc rpc;
    late SalesPricingRepository repo;

    setUp(() {
      rpc = _RecordingRpc();
      repo = SalesPricingRepository(
        rpc: rpc,
        tenantId: () async => parityTenantId,
      );
    });

    test('params_preview_sales_working_state_pricing', () async {
      rpc.nextCallResult = sampleSalesPreviewJson();
      final result = await repo.preview(
        storeId: parityStoreId,
        customerId: parityCustomerId,
        currencyCode: 'VND',
        contextVersion: 3,
        effectiveAt: parityEffectiveAt,
        lines: const [
          new_models.SalesPricingLineInput(
            localLineId: 'line-1',
            productId: parityProductId,
            productUnitId: parityProductUnitId,
            quantityMicros: 1000000,
          ),
          new_models.SalesPricingLineInput(
            localLineId: 'line-2',
            productId: '55555555-5555-4555-8555-555555555555',
            productUnitId: '66666666-6666-4666-8666-666666666666',
            quantityMicros: 2000000,
            manualUnitPriceMinor: 85000,
          ),
        ],
      );
      expect(rpc.calls, hasLength(1));
      expect(rpc.calls.single.schema, 'pricing');
      expect(rpc.calls.single.rpc, 'preview_sales_working_state_pricing');
      expect(rpc.calls.single.params, equals(expectedSalesPreviewParams));
      expectSalesPreview(result);
    });

    test('params_evaluate_sales_manual_price', () async {
      rpc.nextCallResult = sampleSalesManualEvaluationJson();
      final result = await repo.evaluateManualPrice(
        storeId: parityStoreId,
        customerId: parityCustomerId,
        productId: parityProductId,
        productUnitId: parityProductUnitId,
        quantityMicros: 1000000,
        currencyCode: 'VND',
        contextVersion: 3,
        manualUnitPriceMinor: 90000,
        acknowledgeBelowFloor: false,
      );
      expect(rpc.calls, hasLength(1));
      expect(rpc.calls.single.schema, 'pricing');
      expect(rpc.calls.single.rpc, 'evaluate_sales_manual_price');
      expect(
        rpc.calls.single.params,
        equals(expectedSalesManualEvaluationParams),
      );
      expectSalesManualEvaluation(result);
    });

    test(
      'params_preview_sales_working_state_pricing_lowercase_currency',
      () async {
        rpc.nextCallResult = sampleSalesPreviewJson();
        final result = await repo.preview(
          storeId: parityStoreId,
          customerId: parityCustomerId,
          currencyCode: ' vnd ',
          contextVersion: 3,
          effectiveAt: parityEffectiveAt,
          lines: const [
            new_models.SalesPricingLineInput(
              localLineId: 'line-1',
              productId: parityProductId,
              productUnitId: parityProductUnitId,
              quantityMicros: 1000000,
            ),
            new_models.SalesPricingLineInput(
              localLineId: 'line-2',
              productId: '55555555-5555-4555-8555-555555555555',
              productUnitId: '66666666-6666-4666-8666-666666666666',
              quantityMicros: 2000000,
              manualUnitPriceMinor: 85000,
            ),
          ],
        );
        expect(rpc.calls, hasLength(1));
        expect(rpc.calls.single.params, equals(expectedSalesPreviewParams));
        expectSalesPreview(result);
      },
    );

    test('params_evaluate_sales_manual_price_lowercase_currency', () async {
      rpc.nextCallResult = sampleSalesManualEvaluationJson();
      final result = await repo.evaluateManualPrice(
        storeId: parityStoreId,
        customerId: parityCustomerId,
        productId: parityProductId,
        productUnitId: parityProductUnitId,
        quantityMicros: 1000000,
        currencyCode: ' vnd ',
        contextVersion: 3,
        manualUnitPriceMinor: 90000,
        acknowledgeBelowFloor: false,
      );
      expect(rpc.calls, hasLength(1));
      expect(
        rpc.calls.single.params,
        equals(expectedSalesManualEvaluationParams),
      );
      expectSalesManualEvaluation(result);
    });
  });
}

class _RpcCall {
  _RpcCall(this.schema, this.rpc, this.params);
  final String schema;
  final String rpc;
  final Map<String, dynamic>? params;
}

class _RecordingRpc implements SupabaseRpc {
  final calls = <_RpcCall>[];
  Object? nextCallResult;
  Object? errorToThrow;

  @override
  Future<dynamic> call(
    String schema,
    String rpc, {
    Map<String, dynamic>? params,
  }) async {
    calls.add(_RpcCall(schema, rpc, params));
    if (errorToThrow != null) {
      if (errorToThrow is AppException) {
        throw errorToThrow!;
      }
      throw AppException.from(errorToThrow!);
    }
    return nextCallResult;
  }

  @override
  Future<List<Map<String, dynamic>>> rows(
    String schema,
    String rpc, {
    Map<String, dynamic>? params,
  }) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> firstRow(
    String schema,
    String rpc, {
    Map<String, dynamic>? params,
  }) => throw UnimplementedError();
}
