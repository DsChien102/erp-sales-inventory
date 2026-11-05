// ignore_for_file: implementation_imports, depend_on_referenced_packages

import 'dart:async';

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/pricing/data/customer_price_rule_repository.dart';
import 'package:erp/features/pricing/data/mappers/customer_price_rule_json.dart';
import 'package:erp/features/pricing/data/mappers/sales_pricing_json.dart';
import 'package:erp/features/pricing/data/models.dart' as new_models;
import 'package:erp/features/pricing/data/sales_pricing_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_pricing_application/application.dart' as old_app;
import 'package:vet45_pricing_domain/domain.dart' as old_dom;
import 'package:vet45_pricing_infrastructure/src/domain/customer_price_rule/customer_price_rule_detail_rpc_mapper.dart';
import 'package:vet45_pricing_infrastructure/src/domain/customer_price_rule/customer_price_rule_history_rpc_mapper.dart';
import 'package:vet45_pricing_infrastructure/src/domain/customer_price_rule/customer_price_rule_search_rpc_mapper.dart';
import 'package:vet45_pricing_infrastructure/src/domain/customer_price_rule/pricing_disable_rpc_mapper.dart';
import 'package:vet45_pricing_infrastructure/src/domain/customer_price_rule/pricing_reenable_rpc_mapper.dart';
import 'package:vet45_pricing_infrastructure/src/domain/customer_price_rule/pricing_resolve_applicable_rpc_mapper.dart';
import 'package:vet45_pricing_infrastructure/src/domain/customer_price_rule/pricing_rpc_mapper.dart';
import 'package:vet45_pricing_infrastructure/src/domain/customer_price_rule/pricing_update_rpc_mapper.dart';
import 'package:vet45_pricing_infrastructure/src/domain/customer_price_rule/supabase_customer_price_rule_command_gateway.dart';
import 'package:vet45_pricing_infrastructure/src/domain/sales_pricing/sales_pricing_rpc_mapper.dart';
import 'package:vet45_pricing_infrastructure/src/errors/pricing_error_mapper.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart' as shared_dom;
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'pricing_parity_expectations.dart';

void main() {
  group('old (mappers)', () {
    group('params', () {
      test('params_search_customer_price_rules', () {
        final params = CustomerPriceRuleSearchRpcMapper.params(
          old_app.SearchCustomerPriceRulesQuery(
            tenantId: parityTenantId,
            businessDate: parityBusinessDate,
            q: '  vaccine  ',
            quickFilter: old_app.CustomerPriceRuleQuickFilter.belowFloor,
            statuses: const [
              old_app.CustomerPriceRuleDerivedStatus.applying,
              old_app.CustomerPriceRuleDerivedStatus.notYetEffective,
            ],
            sources: const [
              old_dom.CustomerPriceRuleSourceType.manual,
              old_dom.CustomerPriceRuleSourceType.excelImport,
            ],
            customerId: parityCustomerId,
            productId: parityProductId,
            cursor: '  cursor-1  ',
            limit: 25,
          ),
        );
        expect(params, equals(expectedSearchParams));
      });

      test('params_get_customer_price_rule_detail', () {
        final params = CustomerPriceRuleDetailRpcMapper.params(
          old_app.GetCustomerPriceRuleDetailQuery(
            tenantId: parityTenantId,
            ruleId: parityRuleId,
            businessDate: parityBusinessDate,
          ),
        );
        expect(params, equals(expectedDetailParams));
      });

      test('params_get_customer_price_rule_history', () {
        final params = CustomerPriceRuleHistoryRpcMapper.params(
          old_app.GetCustomerPriceRuleHistoryQuery(
            tenantId: parityTenantId,
            ruleId: parityRuleId,
            cursor: '  cursor-1  ',
            limit: 25,
          ),
        );
        expect(params, equals(expectedHistoryParams));
      });

      test('params_create_customer_price_rule', () {
        final candidate = old_dom.CustomerPriceRule.createManual(
          id: const Uuid().v4(),
          key: old_dom.CustomerPriceRuleKey(
            tenantId: parityTenantId,
            customerId: parityCustomerId,
            productId: parityProductId,
            productUnitId: parityProductUnitId,
          ),
          price: shared_dom.Money(amountMinor: 90000, currencyCode: 'VND'),
          effectivePeriod: old_dom.EffectivePeriod(
            effectiveFrom: parityEffectiveFrom,
            effectiveTo: parityEffectiveTo,
          ),
          actorId: parityActorId,
          validationOutcome: old_dom.RuleValidationOutcome.clear(),
          note: parityRawNote,
        );
        final params = PricingRpcMapper.createParams(
          candidate: candidate,
          idempotencyKey: parityPaddedIdempotencyKey,
          acknowledgeFloorWarning: true,
          acknowledgeOverwrite: true,
        );
        final ruleId = params['p_rule_id'] as String?;
        expect(ruleId, isNotNull);
        expect(Uuid.isValidUUID(fromString: ruleId!), isTrue);
        final withoutRuleId = Map<String, dynamic>.of(params)
          ..remove('p_rule_id');
        expect(withoutRuleId, equals(expectedCreateParamsWithoutRuleId));
      });

      test('params_update_customer_price_rule', () {
        final candidate = old_dom.CustomerPriceRule.reconstitute(
          id: parityRuleId,
          key: old_dom.CustomerPriceRuleKey(
            tenantId: parityTenantId,
            customerId: parityCustomerId,
            productId: parityProductId,
            productUnitId: parityProductUnitId,
          ),
          price: shared_dom.Money(amountMinor: 95000, currencyCode: 'VND'),
          effectivePeriod: old_dom.EffectivePeriod(
            effectiveFrom: parityEffectiveFrom,
            effectiveTo: parityEffectiveTo,
          ),
          actorId: parityActorId,
          validationOutcome: old_dom.RuleValidationOutcome.clear(),
          ruleType: old_dom.CustomerPriceRuleType.specialPrice,
          sourceType: old_dom.CustomerPriceRuleSourceType.manual,
          status: old_dom.CustomerPriceRuleStatus.active,
          reviewStatus: old_dom.CustomerPriceRuleReviewStatus.clear,
          version: 3,
          note: parityRawNote,
        );
        final params = PricingUpdateRpcMapper.updateParams(
          candidate: candidate,
          expectedVersion: 3,
          acknowledgeFloorWarning: true,
          acknowledgeOverwrite: true,
        );
        final ruleId = params['p_rule_id'] as String?;
        expect(ruleId, isNotNull);
        expect(Uuid.isValidUUID(fromString: ruleId!), isTrue);
        final withoutRuleId = Map<String, dynamic>.of(params)
          ..remove('p_rule_id');
        expect(withoutRuleId, equals(expectedUpdateParamsWithoutRuleId));
        expect(params, equals(expectedUpdateParams));
      });

      test('params_disable_customer_price_rule', () async {
        final supabase = _FakePricingRpcSupabase()
          ..registerHandler(
            'disable_customer_price_rule',
            (_) async => sampleDetailJson(),
          );
        final gateway = SupabaseCustomerPriceRuleCommandGateway(
          rpcClient: SupabaseSchemaRpcClient(
            supabase: supabase,
            schema: 'pricing',
            mapError: (e, [_]) => RpcException(e.toString()),
          ),
        );
        final handler = old_app.DisableCustomerPriceRuleCommandHandler(
          commandGateway: gateway,
        );
        await handler.handle(
          old_app.DisableCustomerPriceRuleCommand(
            tenantId: parityTenantId,
            actorId: parityActorId,
            ruleId: parityPaddedRuleId,
            expectedVersion: 3,
            reason: parityBlankReason,
          ),
        );
        expect(supabase.calls.single.params, equals(expectedDisableParams));
        expect(
          PricingDisableRpcMapper.params(
            tenantId: parityTenantId,
            ruleId: parityPaddedRuleId.trim(),
            expectedVersion: 3,
            reason: null,
          ),
          equals(expectedDisableParams),
        );
      });

      test('params_precheck_customer_price_rule_reenable', () {
        final params = PricingReenableRpcMapper.precheckParams(
          old_app.PrecheckCustomerPriceRuleReenableQuery(
            tenantId: parityTenantId,
            ruleId: parityRuleId,
            expectedVersion: 4,
            businessDate: parityBusinessDate,
          ),
        );
        expect(params, equals(expectedPrecheckReenableParams));
      });

      test('params_reenable_customer_price_rule', () {
        final params = PricingReenableRpcMapper.reenableParams(
          old_app.ReenableCustomerPriceRuleCommand(
            tenantId: parityTenantId,
            actorId: parityActorId,
            ruleId: parityPaddedRuleId.trim(),
            expectedVersion: 4,
            businessDate: parityBusinessDate,
            precheckToken: parityPrecheckToken,
            acknowledgeFloorWarning: true,
            acknowledgeOverwrite: true,
          ),
        );
        expect(params, equals(expectedReenableParams));
      });

      test('params_resolve_applicable_customer_price_rule', () {
        final params = PricingResolveApplicableRpcMapper.params(
          old_app.ResolveApplicableCustomerPriceRuleQuery(
            tenantId: parityTenantId,
            customerId: parityPaddedCustomerId,
            productId: parityPaddedProductId,
            productUnitId: parityPaddedProductUnitId,
            businessDate: parityBusinessDate,
          ),
        );
        expect(params, equals(expectedResolveParams));
      });

      test('params_preview_sales_working_state_pricing', () {
        final params = SalesPricingRpcMapper.previewParams(
          old_app.SalesWorkingStatePricingInput(
            tenantId: parityTenantId,
            storeId: parityStoreId,
            customerId: parityCustomerId,
            currencyCode: 'VND',
            contextVersion: 3,
            effectiveAt: parityEffectiveAt,
            lines: const [
              old_app.SalesPricingLineInput(
                localLineId: 'line-1',
                productId: parityProductId,
                productUnitId: parityProductUnitId,
                quantityMicros: 1000000,
              ),
              old_app.SalesPricingLineInput(
                localLineId: 'line-2',
                productId: '55555555-5555-4555-8555-555555555555',
                productUnitId: '66666666-6666-4666-8666-666666666666',
                quantityMicros: 2000000,
                manualUnitPriceMinor: 85000,
              ),
            ],
          ),
        );
        expect(params, equals(expectedSalesPreviewParams));
      });

      test('params_evaluate_sales_manual_price', () {
        final params = SalesPricingRpcMapper.manualEvaluationParams(
          old_app.EvaluateSalesManualPriceQuery(
            tenantId: parityTenantId,
            storeId: parityStoreId,
            customerId: parityCustomerId,
            productId: parityProductId,
            productUnitId: parityProductUnitId,
            quantityMicros: 1000000,
            currencyCode: 'VND',
            contextVersion: 3,
            manualUnitPriceMinor: 90000,
            acknowledgeBelowFloor: false,
          ),
        );
        expect(params, equals(expectedSalesManualEvaluationParams));
      });

      test('params_create_customer_price_rule_lowercase_currency', () {
        final candidate = old_dom.CustomerPriceRule.createManual(
          id: const Uuid().v4(),
          key: old_dom.CustomerPriceRuleKey(
            tenantId: parityTenantId,
            customerId: parityCustomerId,
            productId: parityProductId,
            productUnitId: parityProductUnitId,
          ),
          price: shared_dom.Money(amountMinor: 90000, currencyCode: ' vnd '),
          effectivePeriod: old_dom.EffectivePeriod(
            effectiveFrom: parityEffectiveFrom,
            effectiveTo: parityEffectiveTo,
          ),
          actorId: parityActorId,
          validationOutcome: old_dom.RuleValidationOutcome.clear(),
          note: parityRawNote,
        );
        final params = PricingRpcMapper.createParams(
          candidate: candidate,
          idempotencyKey: parityPaddedIdempotencyKey,
          acknowledgeFloorWarning: true,
          acknowledgeOverwrite: true,
        );
        final withoutRuleId = Map<String, dynamic>.of(params)
          ..remove('p_rule_id');
        expect(withoutRuleId, equals(expectedCreateParamsWithoutRuleId));
      });

      test('params_preview_sales_working_state_pricing_lowercase_currency', () {
        final query = old_app.PreviewSalesWorkingStatePricingQuery(
          tenantId: parityTenantId,
          storeId: parityStoreId,
          customerId: parityCustomerId,
          currencyCode: ' vnd ',
          contextVersion: 3,
          effectiveAt: parityEffectiveAt,
          lines: const [
            old_app.SalesPricingLineInput(
              localLineId: 'line-1',
              productId: parityProductId,
              productUnitId: parityProductUnitId,
              quantityMicros: 1000000,
            ),
            old_app.SalesPricingLineInput(
              localLineId: 'line-2',
              productId: '55555555-5555-4555-8555-555555555555',
              productUnitId: '66666666-6666-4666-8666-666666666666',
              quantityMicros: 2000000,
              manualUnitPriceMinor: 85000,
            ),
          ],
        );
        final params = SalesPricingRpcMapper.previewParams(
          old_app.SalesWorkingStatePricingInput(
            tenantId: query.tenantId,
            storeId: query.storeId,
            customerId: query.customerId,
            currencyCode: query.currencyCode,
            contextVersion: query.contextVersion,
            effectiveAt: query.effectiveAt,
            lines: query.lines,
          ),
        );
        expect(params, equals(expectedSalesPreviewParams));
      });

      test('params_evaluate_sales_manual_price_lowercase_currency', () {
        final params = SalesPricingRpcMapper.manualEvaluationParams(
          old_app.EvaluateSalesManualPriceQuery(
            tenantId: parityTenantId,
            storeId: parityStoreId,
            customerId: parityCustomerId,
            productId: parityProductId,
            productUnitId: parityProductUnitId,
            quantityMicros: 1000000,
            currencyCode: ' vnd ',
            contextVersion: 3,
            manualUnitPriceMinor: 90000,
            acknowledgeBelowFloor: false,
          ),
        );
        expect(params, equals(expectedSalesManualEvaluationParams));
      });
    });

    group('json', () {
      test('parse_detail', () {
        final dto = CustomerPriceRuleDetailRpcMapper.detailFromJson(
          sampleDetailJson(),
        );
        expectDetail(dto);
      });

      test('parse_create_result', () {
        final dto = PricingRpcMapper.createResultFromJson(
          sampleCreateResultJson(),
        );
        expectCreateResult(dto);
      });

      test('parse_search_result', () {
        final dto = CustomerPriceRuleSearchRpcMapper.resultFromJson(
          sampleSearchResultJson(),
        );
        expectSearchResult(dto);
      });

      test('parse_history_page', () {
        final page = CustomerPriceRuleHistoryRpcMapper.pageFromJson(
          sampleHistoryPageJson(),
        );
        expectHistoryPage(page);
      });

      test('parse_reenable_precheck', () {
        final dto = PricingReenableRpcMapper.precheckResultFromJson(
          sampleReenablePrecheckJson(),
        );
        expectReenablePrecheck(dto);
      });

      test('parse_resolve_found', () {
        final dto = PricingResolveApplicableRpcMapper.resultFromJson(
          sampleResolveFoundJson(),
        );
        expectResolveFound(dto);
      });

      test('parse_resolve_null', () {
        final dto = PricingResolveApplicableRpcMapper.resultFromJson(
          sampleResolveNullJson(),
        );
        expectResolveNull(dto);
      });

      test('parse_sales_preview', () {
        final dto = SalesPricingRpcMapper.previewFromPayload(
          sampleSalesPreviewJson(),
          expectedContextVersion: 3,
          expectedCurrencyCode: 'VND',
          expectedLocalLineIds: const ['line-1', 'line-2'],
        );
        expectSalesPreview(dto);
      });

      test('parse_sales_manual_evaluation', () {
        final dto = SalesPricingRpcMapper.manualEvaluationFromPayload(
          sampleSalesManualEvaluationJson(),
        );
        expectSalesManualEvaluation(dto);
      });

      test('preview_rejects_mismatched_context', () {
        expect(
          () => SalesPricingRpcMapper.previewFromPayload(
            sampleSalesPreviewJson()..['context_version'] = 99,
            expectedContextVersion: 3,
            expectedCurrencyCode: 'VND',
            expectedLocalLineIds: const ['line-1', 'line-2'],
          ),
          throwsA(
            isA<old_app.PricingBlockedException>().having(
              (e) => e.code,
              'code',
              old_app.PricingBlockedCodes.systemError,
            ),
          ),
        );
      });
    });

    test('old_reenable_drops_acknowledge_overwrite', () async {
      final supabase = _FakePricingRpcSupabase()
        ..registerHandler(
          'reenable_customer_price_rule',
          (_) async => sampleDetailJson(),
        );
      final gateway = SupabaseCustomerPriceRuleCommandGateway(
        rpcClient: SupabaseSchemaRpcClient(
          supabase: supabase,
          schema: 'pricing',
          mapError: (e, [_]) => RpcException(e.toString()),
        ),
      );
      final handler = old_app.ReenableCustomerPriceRuleCommandHandler(
        commandGateway: gateway,
      );

      await handler.handle(
        old_app.ReenableCustomerPriceRuleCommand(
          tenantId: parityTenantId,
          actorId: parityActorId,
          ruleId: parityPaddedRuleId,
          expectedVersion: 4,
          businessDate: parityBusinessDate,
          precheckToken: parityPrecheckToken,
          acknowledgeFloorWarning: true,
          acknowledgeOverwrite: true,
        ),
      );

      final sentParams = supabase.calls.single.params!;
      expect(sentParams['p_rule_id'], parityRuleId);
      expect(sentParams['p_acknowledge_overwrite'], isFalse);
    });

    test('old_map_pricing_rpc_error', () {
      final dup = mapPricingRpcError(
        RpcException(
          '{"code":"DUPLICATE_ACTIVE_RULE","message":"x","details":{"conflictingRuleId":"r1"}}',
        ),
      );
      expect(dup.code, old_app.PricingBlockedCodes.duplicateActiveRule);
      expect(dup.details['conflictingRuleId'], 'r1');

      final overwrite = mapPricingRpcError(
        RpcException('{"code":"OVERWRITE_REQUIRED","message":"x","details":{}}'),
      );
      expect(overwrite.code, old_app.PricingBlockedCodes.systemError);
    });
  });

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

final class _FakePricingRpcSupabase implements SupabaseClient {
  final Map<String, Future<dynamic> Function(Map<String, dynamic>? params)>
  _handlers = {};
  final List<({String functionName, Map<String, dynamic>? params})> calls = [];

  void registerHandler(
    String functionName,
    Future<dynamic> Function(Map<String, dynamic>? params) handler,
  ) {
    _handlers[functionName] = handler;
  }

  @override
  GoTrueClient get auth => _FakeGoTrueClient();

  @override
  SupabaseQuerySchema schema(String schema) {
    if (schema != 'pricing') {
      throw UnsupportedError('Only pricing schema is supported.');
    }
    return _FakePricingQuerySchema(this);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

final class _FakeGoTrueClient implements GoTrueClient {
  @override
  User? get currentUser => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

final class _FakePricingQuerySchema implements SupabaseQuerySchema {
  _FakePricingQuerySchema(this.client);

  final _FakePricingRpcSupabase client;

  @override
  PostgrestFilterBuilder<T> rpc<T>(
    String fn, {
    Map<String, dynamic>? params,
    bool get = false,
  }) => _FakePostgrestRpc<T>(client, fn, params);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

final class _FakePostgrestRpc<T> implements PostgrestFilterBuilder<T> {
  _FakePostgrestRpc(this.client, this.functionName, this.params);

  final _FakePricingRpcSupabase client;
  final String functionName;
  final Map<String, dynamic>? params;

  @override
  Stream<T> asStream() => throw UnsupportedError('stream not supported');

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) => _execute().then(onValue, onError: onError);

  Future<T> _execute() async {
    client.calls.add((functionName: functionName, params: params));
    final handler = client._handlers[functionName];
    if (handler == null) {
      return <String, dynamic>{} as T;
    }
    return await handler(params) as T;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
